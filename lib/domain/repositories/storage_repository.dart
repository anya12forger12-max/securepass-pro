import 'package:securepass_pro/domain/enums/storage_type.dart';

abstract class StorageRepository {
  Future<String?> read(String key, {StorageType type = StorageType.preferences});
  Future<void> write(String key, String value, {StorageType type = StorageType.preferences});
  Future<void> delete(String key, {StorageType type = StorageType.preferences});
  Future<void> clear({StorageType type});
  Future<bool> contains(String key, {StorageType type = StorageType.preferences});
  Future<int> getSize({StorageType type = StorageType.preferences});
}
