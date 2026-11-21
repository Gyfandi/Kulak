import '../../../features/auth/auth_service.dart';
import 'catalog_repository.dart';

/// Katalog memakai ApiClient bersama agar token, refresh, dan timeout mengikuti
/// konfigurasi yang sudah dibuat untuk fitur auth.
final catalogRepository = CatalogRepository(client: apiClient);
