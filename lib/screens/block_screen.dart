import 'package:flutter/material.dart';

import '../services/vpn_service.dart';
import '../theme/app_theme.dart';
import '../widgets/security_app_bar.dart';

class BlockScreen extends StatefulWidget {
  const BlockScreen({
    super.key,
    required this.url,
  });

  static const routeName = '/blocked';

  final String url;

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  bool _isProtected = true;

  @override
  void initState() {
    super.initState();
    _loadProtectionStatus();
  }

  Future<void> _loadProtectionStatus() async {
    final mode = await VpnServiceController.instance.getPrivateDnsMode();
    if (!mounted) {
      return;
    }
    setState(() {
      _isProtected = mode != 'opportunistic' && mode != 'hostname';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SecurityTopBar(
            isProtected: _isProtected,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: colors.error.withValues(alpha: 0.14),
                          ),
                          child: Icon(Icons.shield, size: 48, color: colors.error),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تم حجب هذا الموقع',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            widget.url,
                            style: monoTextStyle(context, size: 14, weight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'استخدم رمز الإزالة من التطبيق فقط عندما ترغب عمداً في استعادة الوصول.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('رجوع'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
