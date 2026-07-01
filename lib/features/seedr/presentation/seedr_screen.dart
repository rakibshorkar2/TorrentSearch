import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/app_providers.dart';

class SeedrScreen extends ConsumerStatefulWidget {
  const SeedrScreen({super.key});

  @override
  ConsumerState<SeedrScreen> createState() => _SeedrScreenState();
}

class _SeedrScreenState extends ConsumerState<SeedrScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Seedr', style: TorrentFlowTheme.headline.copyWith(
          color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
        )),
        backgroundColor: isDark
            ? TorrentFlowTheme.darkSurface.withValues(alpha: 0.85)
            : TorrentFlowTheme.lightSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(
          color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator,
          width: 0.5,
        )),
      ),
      child: SafeArea(
        child: _buildLoginView(isDark),
      ),
    );
  }

  Widget _buildLoginView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(TorrentFlowTheme.standardPadding),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: TorrentFlowTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(CupertinoIcons.cloud, size: 40, color: TorrentFlowTheme.accent),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('Seedr Cloud', style: TorrentFlowTheme.title2.copyWith(
            color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
          )),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Access your Seedr account', style: TorrentFlowTheme.subheadline.copyWith(
            color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
          )),
        ),
        const SizedBox(height: 32),
        GlassCard(
          child: Column(
            children: [
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                ),
                placeholderStyle: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: null,
              ),
              Container(height: 1,
                color: isDark ? TorrentFlowTheme.darkSeparator : TorrentFlowTheme.lightSeparator),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                style: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkText : TorrentFlowTheme.lightText,
                ),
                placeholderStyle: TorrentFlowTheme.body.copyWith(
                  color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CupertinoButton.filled(
          onPressed: _isLoggingIn ? null : _login,
          child: _isLoggingIn
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('Log In'),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('Don\'t have an account? Sign up at seedr.cc',
            style: TorrentFlowTheme.footnote.copyWith(
              color: isDark ? TorrentFlowTheme.darkTextSecondary : TorrentFlowTheme.lightTextSecondary,
            )),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoggingIn = true);
    try {
      await ref.read(seedrServiceProvider).login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Login Failed'),
            content: Text(e.toString()),
            actions: [
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  void _showSuccess() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Connected'),
        content: const Text('Successfully logged in to Seedr.'),
        actions: [
          CupertinoButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
