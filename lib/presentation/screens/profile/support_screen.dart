import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String supportPhone = '+998 90 123 45 67';
  static const String telegramHandle = '@avtoservis_online';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('support'.tr()), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContactCard(
            context,
            icon: Icons.phone,
            title: 'phone'.tr(),
            subtitle: supportPhone,
            onTap: () => _launchPhone(supportPhone),
          ),
          _buildContactCard(
            context,
            icon: Icons.telegram,
            title: 'telegram'.tr(),
            subtitle: telegramHandle,
            onTap: () => _launchTelegram(telegramHandle),
          ),
          const SizedBox(height: 24),
          Text(
            'faq_title'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFaqCard(
            context,
            question: 'faq_payment_methods_question'.tr(),
            answer: 'faq_payment_methods_answer'.tr(),
          ),
          _buildFaqCard(
            context,
            question: 'faq_delivery_time_question'.tr(),
            answer: 'faq_delivery_time_answer'.tr(),
          ),
          _buildFaqCard(
            context,
            question: 'faq_warranty_question'.tr(),
            answer: 'faq_warranty_answer'.tr(),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchPhone(String digits) async {
    try {
      final cleaned = digits.replaceAll(RegExp(r'[^0-9+]'), '');
      final uri = Uri(scheme: 'tel', path: cleaned);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Ошибка при открытии звонилки: $e');
    }
  }

  static Future<void> _launchTelegram(String handleOrLink) async {
    // Если передан @username — пробуем tg://, затем https://t.me/
    final username = handleOrLink.startsWith('@')
        ? handleOrLink.substring(1)
        : handleOrLink.replaceAll('https://t.me/', '');

    final tgUri = Uri.parse('tg://resolve?domain=$username');
    if (await canLaunchUrl(tgUri)) {
      await launchUrl(tgUri);
      return;
    }

    final httpsUri = Uri.parse('https://t.me/$username');
    if (await canLaunchUrl(httpsUri)) {
      await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0D47A1)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqCard(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
