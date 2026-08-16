import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

/// Exception for voice transcription API errors
class GroqWhisperException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  GroqWhisperException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'GroqWhisperException: $message (statusCode: $statusCode, errorCode: $errorCode)';
}

/// Response model for voice transcription
class TranscriptionResponse {
  final String text;
  final String language;
  final double duration;

  TranscriptionResponse({
    required this.text,
    this.language = 'unknown',
    this.duration = 0,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      text: (json['transcription'] ?? json['text'] ?? '').toString(),
      language: json['language']?.toString() ?? 'unknown',
      duration: (json['duration'] ?? 0).toDouble(),
    );
  }
}

/// Service for transcribing audio through the Med_Calci Flask backend.
///
/// The Flutter app never holds the Groq API key and never calls Groq directly.
/// The recorded audio is POSTed to the backend, which reads GROQ_API_KEY from
/// its own environment, forwards the audio to the Groq Whisper API, and returns
/// the transcription (or a clean error).
class GroqWhisperService {
  static const String _debugTag = '[GroqWhisperService]';

  late final Dio _dio;
  final int _timeoutSeconds = 60;

  GroqWhisperService() {
    _initializeDio();
  }

  /// Initialize Dio with proper configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: _timeoutSeconds),
        receiveTimeout: Duration(seconds: _timeoutSeconds),
        sendTimeout: Duration(seconds: _timeoutSeconds),
      ),
    );

    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: false,
          responseHeader: true,
          responseBody: false, // Don't log response bodies
          error: true,
          logPrint: (object) {
            debugPrint('$_debugTag ${object.toString()}');
          },
        ),
      );
    }
  }

  /// Transcribe audio file through the Med_Calci backend.
  ///
  /// Parameters:
  /// - [audioFilePath]: Path to the recorded audio file (.wav, .m4a, etc.)
  ///
  /// Returns: [TranscriptionResponse] with transcribed text
  ///
  /// Throws: [GroqWhisperException] on error
  Future<TranscriptionResponse> transcribeAudio(String audioFilePath) async {
    try {
      // The backend handles Groq authentication; the app only needs its own token.
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw GroqWhisperException(
          message: 'Authentication required for voice transcription.',
          errorCode: 'MISSING_TOKEN',
        );
      }

      // Validate file exists
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw GroqWhisperException(
          message: 'Audio file not found: $audioFilePath',
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      final endpoint = '${ApiConfig.baseUrl}/api/ai/transcribe';

      debugPrint('$_debugTag Uploading audio file: $audioFilePath (${file.lengthSync()} bytes)');

      // Prepare multipart request
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: _getFileName(audioFilePath),
        ),
      });

      debugPrint('$_debugTag Sending transcription request to backend: $endpoint');

      // Send request
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        onSendProgress: (int sent, int total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          debugPrint('$_debugTag Upload progress: $progress%');
        },
      );

      debugPrint('$_debugTag Backend response status: ${response.statusCode}');

      // Handle response
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      if (response.statusCode == 200 && data['success'] == true) {
        final transcription = TranscriptionResponse.fromJson(data);
        debugPrint('$_debugTag Transcription successful: "${transcription.text}"');
        return transcription;
      }

      final errorMessage =
          data['error']?.toString() ?? 'Voice transcription failed. Please try again.';
      throw GroqWhisperException(
        message: errorMessage,
        statusCode: response.statusCode,
        errorCode: 'BAD_RESPONSE',
      );
    } on GroqWhisperException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('$_debugTag Dio error: ${e.message}');
      debugPrint('$_debugTag Error type: ${e.type}');

      String errorMessage;
      String? errorCode;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          errorCode = 'TIMEOUT';
          break;
        case DioExceptionType.badResponse:
          errorMessage = _parseErrorResponse(e.response);
          errorCode = 'BAD_RESPONSE';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Network error. Please check your internet connection.';
          errorCode = 'NETWORK_ERROR';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled.';
          errorCode = 'CANCELLED';
          break;
        case DioExceptionType.badCertificate:
          errorMessage = 'SSL certificate error.';
          errorCode = 'SSL_ERROR';
          break;
        case DioExceptionType.unknown:
          errorMessage = e.message ?? 'Unknown error occurred';
          errorCode = 'UNKNOWN';
          break;
      }

      throw GroqWhisperException(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        errorCode: errorCode,
      );
    } catch (e) {
      debugPrint('$_debugTag Unexpected error: $e');
      throw GroqWhisperException(
        message: 'Unexpected error: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Parse error response from backend
  String _parseErrorResponse(Response? response) {
    if (response == null) return 'Unknown error';

    try {
      final data = response.data;
      if (data is Map) {
        final error = data['error'];
        if (error is Map) {
          return error['message'] ?? error['type'] ?? 'Voice transcription failed';
        }
        if (error != null) return error.toString();
        return data['message']?.toString() ?? 'Voice transcription failed';
      }
      return 'HTTP ${response.statusCode}';
    } catch (_) {
      return 'HTTP ${response.statusCode}';
    }
  }

  /// Get file name from path
  String _getFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}