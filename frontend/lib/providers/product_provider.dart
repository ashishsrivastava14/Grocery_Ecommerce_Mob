import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Categories
final categoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/products/categories');
  final data = response.data['data'] as List;
  return data.map((e) => ProductCategory.fromJson(e)).toList();
});

// Featured products
final featuredProductsProvider =
    FutureProvider<List<Product>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/products', queryParams: {
    'is_featured': true,
    'page_size': 10,
  });
  final data = response.data['data'] as List;
  return data.map((e) => Product.fromJson(e)).toList();
});

// Popular products (by total_sold)
final popularProductsProvider =
    FutureProvider<List<Product>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/products', queryParams: {
    'sort_by': 'total_sold',
    'sort_order': 'desc',
    'page_size': 10,
  });
  final data = response.data['data'] as List;
  return data.map((e) => Product.fromJson(e)).toList();
});

// Products by category
final categoryProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/products', queryParams: {
    'category_id': categoryId,
    'page_size': 50,
  });
  final data = response.data['data'] as List;
  return data.map((e) => Product.fromJson(e)).toList();
});

// Product detail
final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/products/$id');
  return Product.fromJson(response.data['data']);
});

// Product search
final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/products/search', queryParams: {'q': query});
  final data = response.data['data'] as List;
  return data.map((e) => Product.fromJson(e)).toList();
});
