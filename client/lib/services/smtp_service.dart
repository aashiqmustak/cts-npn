import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SmtpEmailService {
  // Configuration Credentials (Gmail SMTP)
  static const String _senderEmail = 'sago23223@gmail.com';
  static const String _appPassword = 'awda nwke vegc mvtr'; // 16-char Google App Password (cts-test)
  static const String _senderName = 'Alternea Verification';

  /// Generates a random 6-digit OTP code string.
  static String generateOtpCode() {
    final random = math.Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Sends a 6-digit OTP verification code to the target email address.
  static Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    // Web browsers do not support raw TCP sockets to port 587/465.
    if (kIsWeb) {
      if (kDebugMode) {
        print('Running on Web platform: Raw TCP SMTP Sockets are sandboxed by browser. OTP Code: $otpCode');
      }
      return false; // Triggers instant on-screen OTP banner fallback
    }

    try {
      // 1. Create Gmail SMTP Server connection (for Native Desktop / Mobile)
      final smtpServer = gmail(_senderEmail, _appPassword);

      // 2. Build the Email Message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Alternea - Your 6-Digit Verification Code'
        ..html = '''
          <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 32px; background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); color: #ffffff; border-radius: 20px; max-width: 480px; margin: auto; border: 1px solid rgba(13, 148, 136, 0.3);">
            <div style="text-align: center; margin-bottom: 24px;">
              <h2 style="color: #0d9488; font-size: 26px; font-weight: 800; margin: 0;">Alternea Healthcare</h2>
              <p style="color: #94a3b8; font-size: 13px; margin-top: 4px;">Formulary Optimization & Clinical Platform</p>
            </div>
            <p style="font-size: 15px; color: #cbd5e1; line-height: 1.6;">Hello,</p>
            <p style="font-size: 15px; color: #cbd5e1; line-height: 1.6;">Here is your 6-digit verification code to authenticate your account session:</p>
            <div style="background: rgba(13, 148, 136, 0.15); padding: 20px; text-align: center; border-radius: 14px; margin: 28px 0; border: 1px solid rgba(13, 148, 136, 0.4);">
              <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #2dd4bf; font-family: monospace;">$otpCode</span>
            </div>
            <p style="font-size: 12px; color: #64748b; text-align: center; line-height: 1.5;">This verification code will expire in 10 minutes. If you did not request this code, please ignore this message.</p>
            <hr style="border: 0; border-top: 1px solid rgba(255, 255, 255, 0.1); margin: 24px 0;" />
            <p style="font-size: 11px; color: #475569; text-align: center;">&copy; 2026 Alternea Ecosystem. HIPAA Compliant & Secure Authentication.</p>
          </div>
        ''';

      // 3. Send Email via SMTP
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) {
        print('OTP Email sent successfully via SMTP: ${sendReport.toString()}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending OTP email via SMTP: $e');
      }
      return false;
    }
  }
}
