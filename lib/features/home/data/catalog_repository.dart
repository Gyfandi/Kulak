import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/api/api_client.dart';
import '../../../data/api/api_exception.dart';
import 'product.dart';

class CatalogOfflineException implements Exception {
  const CatalogOfflineException();
}

class CatalogTimeoutException implements Exception {
  const CatalogTimeoutException();
}

class CatalogRepository {
  CatalogRepository({
    required ApiClient client,
    Connectivity? connectivity,
    this.useMock = const bool.fromEnvironment(
      'CATALOG_USE_MOCK',
      defaultValue: true,
    ),
  })  : _client = client,
        _connectivity = connectivity ?? Connectivity();

  // TODO(C): pastikan nama endpoint dan bentuk JSON dengan A/backend sebelum
  // mematikan mock. Kontrak yang ada sekarang baru mendokumentasikan auth.
  static const _itemsPath = '/items';
  static const _cacheKey = 'products_json';

  final ApiClient _client;
  final Connectivity _connectivity;
  final bool useMock;
  Future<Box<String>>? _cacheFuture;

  Future<List<Product>> getProducts() async {
    if (await _isOffline()) {
      final cached = await _readProductsCache();
      if (cached != null) return cached;
      if (useMock) return _mockProducts;
      throw const CatalogOfflineException();
    }

    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await _writeProductsCache(_mockProducts);
      return _mockProducts;
    }

    try {
      final response = await _retryNetworkRequest(
        () => _client.dio.get<dynamic>(_itemsPath),
      );
      final products = _parseProducts(response.data);
      await _writeProductsCache(products);
      return products;
    } on DioException catch (error) {
      if (_isNetworkFailure(error)) {
        final cached = await _readProductsCache();
        if (cached != null) return cached;
      }
      if (_isTimeout(error)) throw const CatalogTimeoutException();
      throw ApiException.fromDio(error);
    }
  }

  Future<Product> getProduct(String id) async {
    if (await _isOffline()) {
      final cached = await _readProductsCache();
      final product = cached?.where((item) => item.id.toString() == id).firstOrNull;
      if (product != null) return product;
      if (useMock) return _findMockProduct(id);
      throw const CatalogOfflineException();
    }

    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _findMockProduct(id);
    }

    try {
      final response = await _retryNetworkRequest(
        () => _client.dio.get<dynamic>('$_itemsPath/$id'),
      );
      final payload = response.data;
      final json = payload is Map<String, dynamic> && payload['data'] is Map<String, dynamic>
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      final product = Product.fromJson(json);
      await _upsertProductCache(product);
      return product;
    } on DioException catch (error) {
      if (_isNetworkFailure(error)) {
        final cached = await _readProductsCache();
        final product = cached?.where((item) => item.id.toString() == id).firstOrNull;
        if (product != null) return product;
      }
      if (_isTimeout(error)) throw const CatalogTimeoutException();
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> _isOffline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.none);
  }

  bool _isNetworkFailure(DioException error) =>
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout);

  bool _isTimeout(DioException error) =>
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;

  Future<Response<dynamic>> _retryNetworkRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await request();
      } on DioException catch (error) {
        if (!_isNetworkFailure(error) || attempt >= 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
  }

  List<Product> _parseProducts(dynamic payload) {
    dynamic rows = payload;
    if (payload is Map<String, dynamic>) {
      rows = payload['data'] ?? payload['items'] ?? payload['products'];
      if (rows is Map<String, dynamic>) {
        rows = rows['data'] ?? rows['items'] ?? rows['products'];
      }
    }
    if (rows is! List) {
      throw const FormatException('Format respons daftar barang tidak sesuai.');
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList(growable: false);
  }

  Future<Box<String>> _cacheBox() =>
      _cacheFuture ??= _openCacheBox();

  Future<Box<String>> _openCacheBox() async {
    await Hive.initFlutter();
    return Hive.openBox<String>('kulak_catalog');
  }

  Future<List<Product>?> _readProductsCache() async {
    try {
      final encoded = (await _cacheBox()).get(_cacheKey);
      if (encoded == null) return null;
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeProductsCache(List<Product> products) async {
    try {
      final encoded = jsonEncode(products.map((product) => product.toJson()).toList());
      await (await _cacheBox()).put(_cacheKey, encoded);
    } catch (_) {
      // Cache failure should not hide a successful API response.
    }
  }

  Future<void> _upsertProductCache(Product product) async {
    final cached = await _readProductsCache() ?? <Product>[];
    final updated = cached.where((item) => item.id != product.id).toList()
      ..add(product);
    await _writeProductsCache(updated);
  }

  Product _findMockProduct(String id) => _mockProducts.firstWhere(
        (product) => product.id.toString() == id,
        orElse: () => throw const ApiException(
          message: 'Barang tidak ditemukan.',
          statusCode: 404,
        ),
      );

  static const _mockProducts = <Product>[
    Product(
      id: 1,
      name: 'Sepeda lipat',
      description: 'Sepeda lipat kondisi baik, cocok untuk perjalanan harian.',
      price: 1250000,
      sellerName: 'Rina',
      location: 'Bandung',
      imageUrl: null,
    ),
    Product(
      id: 2,
      name: 'Kamera mirrorless',
      description: 'Kamera ringan untuk belajar fotografi, termasuk baterai.',
      price: 3400000,
      sellerName: 'Dimas',
      location: 'Jakarta',
      imageUrl: null,
    ),
    Product(
      id: 3,
      name: 'Meja belajar',
      description: 'Meja kayu sederhana, masih kokoh dan siap digunakan.',
      price: 450000,
      sellerName: 'Sari',
      location: 'Depok',
      imageUrl: null,
    ),
  ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
