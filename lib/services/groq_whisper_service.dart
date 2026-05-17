import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/api_config.dart';

/// Exception for Groq Whisper API errors
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

/// Response model for Groq Whisper transcription
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
      text: json['text'] ?? '',
      language: json['language'] ?? 'unknown',
      duration: (json['duration'] ?? 0).toDouble(),
    );
  }
}

/// Service for transcribing audio using Groq Whisper API
/// 
/// Handles:
/// - Audio file uploads
/// - Multipart form data encoding
/// - API authentication
/// - Error handling and retries
/// - Response parsing
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
        contentType: 'multipart/form-data',
      ),
    );

    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: false, // Don't log full response body
          error: true,
          logPrint: (object) {
            debugPrint('$_debugTag ${object.toString()}');
          },
        ),
      );
    }
  }

  /// Transcribe audio file using Groq Whisper API
  /// 
  /// Parameters:
  /// - [audioFilePath]: Path to the audio file (.wav, .m4a, etc.)
  /// 
  /// Returns: [TranscriptionResponse] with transcribed text
  /// 
  /// Throws: [GroqWhisperException] on error
  Future<TranscriptionResponse> transcribeAudio(String audioFilePath) async {
    try {
      // Validate API key
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw GroqWhisperException(
          message: 'Groq API key not configured. Set GROQ_API_KEY environment variable.',
          errorCode: 'MISSING_API_KEY',
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

      debugPrint('$_debugTag Uploading audio file: $audioFilePath (${file.lengthSync()} bytes)');

      // Prepare multipart request
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: _getFileName(audioFilePath),
        ),
        'model': ApiConfig.groqModel,
        'language': 'en', // You can make this configurable
      });

      debugPrint('$_debugTag Sending transcription request to ${ApiConfig.groqApiUrl}');

      // Send request
      final response = await _dio.post(
        ApiConfig.groqApiUrl,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
        onSendProgress: (int sent, int total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          debugPrint('$_debugTag Upload progress: $progress%');
        },
      );

      debugPrint('$_debugTag Response status: ${response.statusCode}');
      debugPrint('$_debugTag Response data: ${response.data}');

      // Handle successful response
      if (response.statusCode == 200) {
        final transcription = TranscriptionResponse.fromJson(response.data);
        debugPrint('$_debugTag Transcription successful: "${transcription.text}"');
        return transcription;
      } else {
        throw GroqWhisperException(
          message: 'Unexpected response status: ${response.statusCode}',
          statusCode: response.statusCode,
          errorCode: 'UNEXPECTED_STATUS',
        );
      }
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

  /// Parse error response from API
  String _parseErrorResponse(Response? response) {
    if (response == null) return 'Unknown error';

    try {
      final data = response.data;
      if (data is Map) {
        final error = data['error'];
        if (error is Map) {
          return error['message'] ?? error['type'] ?? 'API error';
        }
        return data['message'] ?? 'API error';
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
