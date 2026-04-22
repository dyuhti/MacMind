"""
Email utilities for sending OTP and notifications
Uses SMTP with Gmail
"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from dotenv import load_dotenv

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
        True if email sent successfully, False otherwise
    """
    try:
        # Get email credentials from environment
        sender_email = os.getenv('EMAIL_USER')
        sender_password = os.getenv('EMAIL_PASS')
        
        if not sender_email or not sender_password:
            print('Email credentials not configured in .env')
            return False
        
        # Create message
        message = MIMEMultipart('alternative')
        message['Subject'] = 'Password Reset OTP - Med Calci App'
        message['From'] = sender_email
        message['To'] = recipient_email
        
        # Email body
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
        
        # Attach both plain text and HTML
        part1 = MIMEText(text_body, 'plain')
        part2 = MIMEText(html_body, 'html')
        message.attach(part1)
        message.attach(part2)
        
        # Send email via SMTP
        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, recipient_email, message.as_string())
        
        print(f'OTP email sent successfully to {recipient_email}')
        return True
    
    except smtplib.SMTPAuthenticationError:
        print('Error: SMTP authentication failed. Check EMAIL_USER and EMAIL_PASS in .env')
        return False
    except smtplib.SMTPException as e:
        print(f'Error: SMTP error occurred: {str(e)}')
        return False
    except Exception as e:
        print(f'Error sending email: {str(e)}')
        return False
