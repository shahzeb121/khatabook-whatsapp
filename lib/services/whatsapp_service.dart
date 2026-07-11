import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles sending things to WhatsApp WITHOUT the WhatsApp Business API.
/// v1 uses two approaches:
///  1) share_plus -> opens the native share sheet with the PDF file + text.
///     The user picks WhatsApp themselves, then picks the contact/chat.
///     (Android does not allow 3rd party apps to pre-select a WhatsApp
///     contact AND attach a file at the same time - this is a WhatsApp
///     limitation, not ours.)
///  2) url_launcher with whatsapp://send?phone=...&text=... -> opens a
///     SPECIFIC contact's chat directly with prefilled text (no attachment).
///     Used for text-only reminders.
class WhatsAppService {
  /// Normalizes a Pakistani phone number to +92xxxxxxxxxx format.
  static String normalizePhone(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('0')) {
      phone = '+92${phone.substring(1)}';
    } else if (phone.startsWith('92')) {
      phone = '+$phone';
    } else if (!phone.startsWith('+')) {
      phone = '+92$phone';
    }
    return phone;
  }

  /// Share a PDF file (invoice or ledger) with a prefilled message.
  /// Opens the general Android share sheet - user taps WhatsApp there.
  static Future<void> sharePdf({
    required String filePath,
    required String message,
  }) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: message,
    );
  }

  /// Opens a specific customer's WhatsApp chat directly with prefilled text.
  /// Used by "Sab Ko Reminder" (send reminder to each customer one by one).
  static Future<bool> sendTextDirectToChat({
    required String phone,
    required String message,
  }) async {
    final normalized = normalizePhone(phone).replaceAll('+', '');
    final uri = Uri.parse(
      "https://wa.me/$normalized?text=${Uri.encodeComponent(message)}",
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Standard invoice message text (Roman Urdu + English mix).
  static String invoiceMessage({
    required String customerName,
    required String shopName,
    required int invoiceId,
    required int amount,
    required String dueDateStr,
  }) {
    return "Hi $customerName, $shopName se Invoice #$invoiceId Rs.$amount attached hai. Due: $dueDateStr.";
  }

  /// Standard ledger message text (Roman Urdu + English mix).
  static String ledgerMessage({
    required String customerName,
    required String shopName,
    required String startStr,
    required String endStr,
    required int totalBaqi,
  }) {
    return "Hi $customerName, $shopName ka $startStr se $endStr tak ka hisaab attached hai. Total baqi: Rs.$totalBaqi. Shukriya!";
  }

  /// Reminder-only message text (used for bulk "Sab Ko Reminder").
  static String reminderMessage({
    required String customerName,
    required String shopName,
    required int totalBaqi,
  }) {
    return "Hi $customerName, $shopName ki taraf se yaad dahani: Aap ka Rs.$totalBaqi baqaya hai. Jald ada karne ki zehmat karein. Shukriya!";
  }
}
