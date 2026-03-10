import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';
import '../services/vpn_service.dart';
import '../theme/app_theme.dart';
import '../utils/code_generator.dart';
import '../widgets/error_banner.dart';
import '../widgets/security_app_bar.dart';

class AddSiteScreen extends StatefulWidget {
  const AddSiteScreen({super.key});

  static const routeName = '/add-site';

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  bool _submitting = false;
  bool _isProtected = true;
  String? _error;
  late String _generatedCode;

  @override
  void initState() {
    super.initState();
    _generatedCode = CodeGenerator.generate();
    _loadProtectionStatus();
  }

  @override
  void dispose() {
    _urlController.dispose();
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
    return Scaffold(
      body: Column(
        children: [
          SecurityTopBar(
            isProtected: _isProtected,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    // Designer note: Elevated bottom-sheet layout keeps focus on one decisive action.
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حجب نطاق', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل نطاقاً مثل youtube.com. سيتم تجاهل البروتوكولات والمسارات تلقائياً.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _urlController,
                              textDirection: TextDirection.ltr,
                              style: monoTextStyle(context, size: 15, weight: FontWeight.w600),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.public),
                                labelText: 'رابط الموقع أو النطاق',
                                hintText: 'example.com',
                              ),
                              keyboardType: TextInputType.url,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال موقع.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'رمز الإزالة',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _copyRemovalCode,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          _generatedCode,
                                          style: monoTextStyle(context, size: 15, weight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.copy_outlined,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط للنسخ والاحتفاظ بهذا الرمز بأمان. ستحتاجه لإزالة الحجب.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              ErrorBanner(
                                message: _error!,
                                onRetry: _handleSubmit,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submitting ? null : _handleSubmit,
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('تأكيد الحجب'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.08, end: 0, duration: 320.ms, curve: Curves.easeOutCubic)
                        .fadeIn(duration: 280.ms),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyRemovalCode() async {
    await Clipboard.setData(ClipboardData(text: _generatedCode));
    await HapticFeedback.lightImpact();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رمز الإزالة.')),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await HapticFeedback.selectionClick();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final generatedCode = await DatabaseService.instance.addBlockedSite(
        _urlController.text,
        removalCode: _generatedCode,
      );
      await VpnServiceController.instance.refreshBlocklist();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('تم الحفظ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('احتفظ بهذا الرمز بأمان. ستحتاجه لإزالة الحجب.'),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    generatedCode,
                    style: monoTextStyle(context, size: 16, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: generatedCode));
                  await HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.copy),
                label: const Text('نسخ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('تم'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      setState(() {
        _error = error.message?.toString() ?? 'عنوان غير صالح.';
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}
