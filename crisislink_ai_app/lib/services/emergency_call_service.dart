import 'package:url_launcher/url_launcher.dart';

class EmergencyCallService {
  /// Emergency number (112 in EU, 999 in UK, 911 in US)
  static const String emergencyNumber = '112';

  /// Initiates an emergency call to 112
  /// Returns true if call was initiated successfully, false otherwise
  static Future<bool> callEmergency() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Sends an SMS to an emergency contact with SOS message
  static Future<bool> sendEmergencySms(
    String phoneNumber, {
    required String message,
  }) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Dials a specific phone number
  static Future<bool> callPhoneNumber(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
