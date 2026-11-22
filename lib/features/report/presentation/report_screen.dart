import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/report_repository.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.productId, this.productName});

  final String productId;
  final String? productName;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _detailCtrl = TextEditingController();
  String? _reason;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    final detail = _detailCtrl.text.trim();

    if (reason == null) {
      setState(() => _error = 'Pilih alasan laporan terlebih dahulu.');
      return;
    }
    if (reason == ReportRepository.otherReason && detail.isEmpty) {
      setState(() => _error = 'Jelaskan masalahnya pada kolom keterangan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await reportRepository.submit(
        productId: widget.productId,
        reason: reason,
        detail: detail,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Laporan terkirim. Terima kasih.')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Laporan gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Laporkan barang')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.productName != null) ...[
              Text(widget.productName!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
            ],
            Text(
              'Pilih alasan laporan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final reason in ReportRepository.reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !_submitting,
                onTap: () => setState(() {
                  _reason = reason;
                  _error = null;
                }),
                leading: Icon(
                  _reason == reason
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _reason == reason ? theme.colorScheme.primary : null,
                ),
                title: Text(reason),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailCtrl,
              enabled: !_submitting,
              maxLength: 300,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Keterangan tambahan',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Kirim laporan'),
            ),
          ],
        ),
      ),
    );
  }
}