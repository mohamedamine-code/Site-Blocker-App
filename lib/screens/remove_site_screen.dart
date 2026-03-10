import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/database_service.dart';
import '../services/vpn_service.dart';

class RemoveSiteScreen extends StatefulWidget {
  const RemoveSiteScreen({super.key});

  static const routeName = '/remove-site';

  @override
  State<RemoveSiteScreen> createState() => _RemoveSiteScreenState();
}

class _RemoveSiteScreenState extends State<RemoveSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Blocked Site'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Unblock with code',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Enter the removal code generated when you blocked the site.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Removal Code',
                suffixIcon: IconButton(
                  tooltip: 'Paste',
                  icon: const Icon(Icons.paste),
                  onPressed: _processing
                      ? null
                      : () async {
                          final clipboard = await Clipboard.getData('text/plain');
                          final text = clipboard?.text?.trim();
                          if (text == null || text.isEmpty) {
                            return;
                          }
                          _codeController.text = text;
                        },
                ),
              ),
              maxLength: 32,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the generated code';
                }
                if (value.trim().length < 8) {
                  return 'Code must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _handleRemoval,
                icon: _processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Remove Site'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRemoval() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final removed = await DatabaseService.instance
          .removeBlockedSiteByCode(_codeController.text.trim());
      if (!removed) {
        setState(() {
          _error = 'No site matched that removal code.';
        });
        return;
      }
      await VpnServiceController.instance.refreshBlocklist();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString() ?? 'Invalid code');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }
}
