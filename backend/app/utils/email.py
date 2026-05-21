"""
Email utilities for sending OTP and notifications.
Uses SendGrid for outbound email delivery.
"""
import logging
import os
import traceback

from dotenv import load_dotenv
from flask import current_app
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail


# Load environment variables
load_dotenv()


def send_otp_email(recipient_email, user_name, otp):
    """
    Send OTP to user via email

    Args:
        recipient_email: Email address to send OTP to
        user_name: User's name for personalization
        otp: 6-digit OTP code

    Returns:
        Dictionary with success status and error details when available
    """
    try:
        email_user = os.getenv('EMAIL_USER', '').strip()
        sendgrid_api_key = os.getenv('SENDGRID_API_KEY', '').strip()

        if not email_user or not sendgrid_api_key:
            error_message = 'Email credentials not configured in .env'
            try:
                current_app.logger.error(error_message)
            except Exception:
                logging.error(error_message)
            return {'success': False, 'error': error_message}

        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; background-color: #f7fafc; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 12px; padding: 32px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <h1 style="color: #1f2937; margin-top: 0; font-size: 24px;">Password Reset Request</h1>
                    <p style="color: #374151; font-size: 16px; line-height: 1.5;">Hi {user_name},</p>
                    <p style="color: #374151; font-size: 16px; line-height: 1.5;">We received a request to reset your password. Use the OTP below to proceed:</p>

                    <div style="background-color: #eaf4ff; border: 2px solid #d1e3ff; border-radius: 8px; padding: 24px; text-align: center; margin: 24px 0;">
                        <p style="margin: 0; font-size: 14px; color: #6b7280;">Your OTP Code</p>
                        <p style="margin: 12px 0; font-size: 32px; font-weight: bold; color: #3b82f6; letter-spacing: 4px;">{otp}</p>
                    </div>

                    <p style="color: #6b7280; font-size: 14px; line-height: 1.5;">
                        <strong>This OTP will expire in 5 minutes.</strong>
                    </p>

                    <p style="color: #374151; font-size: 16px; line-height: 1.5;">If you didn't request a password reset, you can safely ignore this email.</p>

                    <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;">

                    <p style="color: #6b7280; font-size: 12px; text-align: center; margin: 0;">
                        MacMind © 2026. All rights reserved.
                    </p>
                </div>
            </body>
        </html>
        """

        text_body = f"""
        Password Reset Request

        Hi {user_name},

        We received a request to reset your password. Use the OTP below to proceed:

        Your OTP Code: {otp}

        This OTP will expire in 5 minutes.

        If you didn't request a password reset, you can safely ignore this email.

        MacMind © 2026
        """

        message = Mail(
            from_email=email_user,
            to_emails=recipient_email,
            subject='Password Reset OTP - Med Calci App',
            plain_text_content=text_body,
            html_content=html_body,
        )

        sg = SendGridAPIClient(sendgrid_api_key)
        sg.send(message)

        print(f'OTP email sent successfully to {recipient_email}')
        return {'success': True}

    except Exception as e:
        msg = f'Error sending email: {str(e)}'
        try:
            current_app.logger.error(msg)
            current_app.logger.error(traceback.format_exc())
        except Exception:
            logging.error(msg)
            logging.error(traceback.format_exc())
        return {'success': False, 'error': msg}
