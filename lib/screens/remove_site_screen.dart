import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';
import '../services/vpn_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_banner.dart';
import '../widgets/security_app_bar.dart';

class RemoveSiteScreen extends StatefulWidget {
  const RemoveSiteScreen({super.key});

  static const routeName = '/remove-site';

  @override
  State<RemoveSiteScreen> createState() => _RemoveSiteScreenState();
}

class _RemoveSiteScreenState extends State<RemoveSiteScreen> {
  final _codeController = TextEditingController();

  bool _processing = false;
  bool _isProtected = true;
  String? _error;
  int _shakeTick = 0;

  @override
  void initState() {
    super.initState();
    _loadProtectionStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
    final canSubmit = _codeController.text.trim().length == 16 && !_processing;

    return Scaffold(
      body: Column(
        children: [
          SecurityTopBar(
            isProtected: _isProtected,
          ),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.lock, color: colors.error),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'إزالة صعبة',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا يمكن التراجع عن هذا الإجراء',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أدخل رمز الإزالة المكون من 16 حرفاً الذي تم إنشاؤه عند حجب الموقع.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          style: monoTextStyle(context, size: 15),
                          textDirection: TextDirection.ltr,
                          maxLength: 16,
                          decoration: InputDecoration(
                            labelText: 'رمز الإزالة',
                            hintText: 'XXXXXXXXXXXXXXXX',
                            suffixIcon: IconButton(
                              tooltip: 'لصق',
                              icon: const Icon(Icons.paste),
                              onPressed: _processing
                                  ? null
                                  : () async {
                                      final clipboard = await Clipboard.getData('text/plain');
                                      final text = clipboard?.text?.trim();
                                      if (text == null || text.isEmpty) {
                                        return;
                                      }
                                      await HapticFeedback.selectionClick();
                                      setState(() {
                                        _codeController.text = text;
                                        _error = null;
                                      });
                                    },
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {
                              _error = null;
                            });
                          },
                          onSubmitted: (_) {
                            if (!canSubmit) {
                              _triggerWrongCodeFeedback();
                            }
                          },
                        )
                            .animate(target: _shakeTick.toDouble())
                            .shake(
                              hz: 4,
                              offset: const Offset(8, 0),
                              duration: 360.ms,
                            ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  ErrorBanner(message: _error!, onRetry: _handleRemoval),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSubmit ? _handleRemoval : null,
                    child: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('تأكيد الإزالة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _triggerWrongCodeFeedback() {
    HapticFeedback.vibrate();
    setState(() {
      _shakeTick += 1;
    });
  }

  Future<void> _handleRemoval() async {
    final code = _codeController.text.trim();
    if (code.length != 16) {
      _triggerWrongCodeFeedback();
      setState(() {
        _error = 'يجب أن يكون الرمز 16 حرفاً بالضبط.';
      });
      return;
    }

    await HapticFeedback.selectionClick();
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final removed = await DatabaseService.instance.removeBlockedSiteByCode(code);
      if (!removed) {
        _triggerWrongCodeFeedback();
        setState(() {
          _error = 'الرمز غير صحيح. لا يوجد موقع محجوب يطابق هذا الرمز.';
        });
        return;
      }

      await VpnServiceController.instance.refreshBlocklist();
      await HapticFeedback.mediumImpact();

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }
}
