// ignore_for_file: file_names

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/blocked_site.dart';
import '../services/database_service.dart';
import '../services/vpn_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_tile.dart';
import '../widgets/error_banner.dart';
import '../widgets/security_app_bar.dart';
import 'add_site_screen.dart';
import 'remove_site_screen.dart';

class BlockedSiteInfoScreen extends StatefulWidget {
  const BlockedSiteInfoScreen({super.key});

  static const routeName = '/blocked-site-info';

  @override
  State<BlockedSiteInfoScreen> createState() => _BlockedSiteInfoScreenState();
}

class _BlockedSiteInfoScreenState extends State<BlockedSiteInfoScreen> {
  final _database = DatabaseService.instance;
  final _vpnService = VpnServiceController.instance;

  final Set<int> _revealedCodeIds = <int>{};
  bool _loading = true;
  bool _isProtected = true;
  String? _errorMessage;
  List<BlockedSite> _sites = <BlockedSite>[];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSites();
  }

  Future<void> _loadSites() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _database.fetchBlockedSites(),
        _vpnService.getPrivateDnsMode(),
      ]);

      if (!mounted) {
        return;
      }

      final sites = results[0] as List<BlockedSite>;
      final privateDnsMode = results[1] as String;

      setState(() {
        _sites = sites;
        _isProtected = privateDnsMode != 'opportunistic' && privateDnsMode != 'hostname';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshSites() async {
    await _vpnService.refreshBlocklist();
    await _loadSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SecurityTopBar(
            isProtected: _isProtected,
            actions: [
              TopBarActionButton(
                tooltip: 'إزالة يدوية',
                onPressed: _openRemoveScreen,
                icon: Icons.lock_open_outlined,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSites,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      ActionTile(
                        label: 'إضافة موقع',
                        icon: Icons.add_circle_outline,
                        onTap: _openAddSite,
                      ),
                      const SizedBox(width: 8),
                      ActionTile(
                        label: 'إزالة بالرمز',
                        icon: Icons.key_outlined,
                        color: Theme.of(context).colorScheme.error,
                        onTap: _openRemoveScreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    ErrorBanner(
                      message: _errorMessage!,
                      onRetry: _loadSites,
                    )
                  else if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_sites.isEmpty)
                    _buildEmptyState()
                  else
                    ..._sites.asMap().entries.map((entry) {
                      final index = entry.key;
                      final site = entry.value;
                      return _buildAnimatedSiteTile(site, index);
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Designer note: The empty state includes a direct CTA to reduce decision friction for first-time users.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مواقع محجوبة بعد',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'أضف أول نطاق مشتت لبدء الحماية والتركيز.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openAddSite,
                icon: const Icon(Icons.add),
                label: const Text('إضافة موقع محجوب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSiteTile(BlockedSite site, int index) {
    final codePreview = _revealedCodeIds.contains(site.id)
        ? site.removalCodeHash.substring(0, 16)
        : '••••••••••••••••';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey<int>(site.id ?? index),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmRemoval(site),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.error),
          ),
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        child: Card(
          child: ListTile(
            minVerticalPadding: 12,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: _buildFaviconPlaceholder(site.url),
            title: Text(
              site.url,
              style: monoTextStyle(context, size: 15, weight: FontWeight.w700),
              textDirection: TextDirection.ltr,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _toggleCodeReveal(site.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _revealedCodeIds.contains(site.id) ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            codePreview,
                            style: monoTextStyle(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate(delay: Duration(milliseconds: 35 * index)).slideX(
            begin: 0.08,
            end: 0,
            duration: 320.ms,
            curve: Curves.easeOutCubic,
          ).fadeIn(duration: 280.ms),
    );
  }

  Widget _buildFaviconPlaceholder(String domain) {
    final firstChar = domain.isNotEmpty ? domain.characters.first.toUpperCase() : '?';
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 20,
      backgroundColor: colors.surfaceContainerHighest,
      child: Text(
        firstChar,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.primary),
      ),
    );
  }

  Future<void> _toggleCodeReveal(int? siteId) async {
    if (siteId == null) {
      return;
    }
    await HapticFeedback.selectionClick();
    setState(() {
      if (_revealedCodeIds.contains(siteId)) {
        _revealedCodeIds.remove(siteId);
      } else {
        _revealedCodeIds.add(siteId);
      }
    });
  }

  Future<bool> _confirmRemoval(BlockedSite site) async {
    if (site.id == null) {
      return false;
    }

    final removed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CodeConfirmationSheet(
        site: site,
        onConfirm: (code) => _database.removeBlockedSiteWithCode(
          siteId: site.id!,
          removalCode: code,
        ),
      ),
    );

    if (removed == true) {
      await HapticFeedback.mediumImpact();
      await _vpnService.refreshBlocklist();
      await _loadSites();
      return true;
    }

    return false;
  }

  Future<void> _openAddSite() async {
    await HapticFeedback.lightImpact();
    if (!mounted) {
      return;
    }
    final added = await Navigator.of(context).pushNamed(AddSiteScreen.routeName);
    if (added == true) {
      await _refreshSites();
    }
  }

  Future<void> _openRemoveScreen() async {
    await HapticFeedback.lightImpact();
    if (!mounted) {
      return;
    }
    final removed = await Navigator.of(context).pushNamed(RemoveSiteScreen.routeName);
    if (removed == true) {
      await _refreshSites();
    }
  }
}

class _CodeConfirmationSheet extends StatefulWidget {
  const _CodeConfirmationSheet({
    required this.site,
    required this.onConfirm,
  });

  final BlockedSite site;
  final Future<bool> Function(String code) onConfirm;

  @override
  State<_CodeConfirmationSheet> createState() => _CodeConfirmationSheetState();
}

class _CodeConfirmationSheetState extends State<_CodeConfirmationSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  int _shakeTick = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final enteredHash = sha256.convert(utf8.encode(_controller.text.trim())).toString();
    final exactMatch = enteredHash == widget.site.removalCodeHash;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  'تأكيد الإزالة',
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
            'أدخل رمز الإزالة المكون من 16 حرفاً للموقع:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              widget.site.url,
              style: monoTextStyle(context, size: 14, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            style: monoTextStyle(context, size: 15),
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'أدخل رمز الإزالة',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (!exactMatch) {
                _triggerWrongCodeFeedback();
              }
            },
          )
              .animate(target: _shakeTick.toDouble())
              .shake(
                hz: 4,
                duration: 360.ms,
                offset: const Offset(8, 0),
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !_submitting && exactMatch ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إزالة الموقع'),
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

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
    });

    final removed = await widget.onConfirm(_controller.text.trim());

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (removed) {
      Navigator.of(context).pop(true);
    } else {
      _triggerWrongCodeFeedback();
    }
  }
}
