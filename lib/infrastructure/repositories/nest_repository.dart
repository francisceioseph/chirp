import 'package:chirp/infrastructure/services/secure_nest.dart';
import 'package:flutter/foundation.dart';

abstract class NestRepository<T> {
  @protected
  final ISecureNest nest;

  @protected
  final String boxName;

  @protected
  final Map<String, T> cache = {};

  Map<String, T> get cached => cache;

  NestRepository({required this.nest, required this.boxName});

  Future<void> save(String key, T data);
  Future<T?> get(String key);
  Future<List<T>> list();
}
