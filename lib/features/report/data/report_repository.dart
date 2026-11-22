/// Mengirim laporan barang bermasalah.
///
/// TODO(Adi): endpoint laporan belum ada di docs/api-contract.md. Tanyakan ke
/// backend (A/Pandi) bentuk request-nya, lalu ganti isi [submit] dengan
/// panggilan ke apiClient. Sementara ini hanya meniru proses kirim (mock).
class ReportRepository {
  const ReportRepository();

  static const reasons = <String>[
    'Penipuan atau barang palsu',
    'Barang terlarang',
    'Informasi tidak sesuai',
    'Spam atau iklan ganda',
    'Lainnya',
  ];

  /// Alasan yang mewajibkan keterangan tambahan.
  static const otherReason = 'Lainnya';

  Future<void> submit({
    required String productId,
    required String reason,
    String detail = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}

const reportRepository = ReportRepository();