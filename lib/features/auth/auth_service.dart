import '../../data/api/api_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/storage/token_storage.dart';

/// Instance bersama untuk fitur auth. Sementara sederhana (top-level),
/// nanti bisa dipindah ke state management pilihan A.
final tokenStorage = TokenStorage();
final apiClient = ApiClient(tokenStorage: tokenStorage);

/// useMock: true -> data tiruan. Ubah ke false saat backend A sudah jadi.
final authApi = AuthApi(
  client: apiClient,
  storage: tokenStorage,
  useMock: true,
);