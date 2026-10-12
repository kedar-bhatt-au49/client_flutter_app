import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/license_service.dart';

/// Full-screen gate shown when the demo license is expired or switched off.
class DemoLockScreen extends StatefulWidget {
  final LicenseStatus status;
  final Future<LicenseStatus> Function() onRetry;

  const DemoLockScreen({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  State<DemoLockScreen> createState() => _DemoLockScreenState();
}

class _DemoLockScreenState extends State<DemoLockScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    final s = await widget.onRetry();
    if (!mounted) return;
    setState(() => _checking = false);
    if (s.licensed) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This demo is still locked.')),
      );
    }
  }

  Future<void> _call() async {
    await launchUrl(Uri.parse('tel:+91${GSUsers.founderPhone}'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsapp() async {
    final msg = Uri.encodeComponent(
        'Hello, my Solar Client App demo has expired. I would like to continue.');
    await launchUrl(
        Uri.parse('https://wa.me/91${GSUsers.founderPhone}?text=$msg'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.status.reason == 'disabled';
    final title = disabled ? 'Demo Deactivated' : 'Demo Expired';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071440), Color(0xFF0B1F5C), Color(0xFF1E5BD8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.lock_clock_rounded,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    disabled
                        ? 'This demo has been deactivated. Please contact Global Solar 2.0 to continue using the app.'
                        : 'Your 7-day demo has ended. Contact Global Solar 2.0 to activate the full version and keep your data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _call,
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('Call Us'),
                          style: FilledButton.styleFrom(
                            backgroundColor: GSColors.gold500,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _whatsapp,
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('WhatsApp'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _checking ? null : _retry,
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded,
                            size: 18, color: Colors.white),
                    label: const Text('Check again',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Text('Global Solar 2.0 • Client Management',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
