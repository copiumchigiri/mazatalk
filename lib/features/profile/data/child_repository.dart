import '../domain/child_profile.dart';

abstract class ChildRepository {
  Future<List<ChildProfile>> loadChildren();
  Future<void> saveChildren(List<ChildProfile> children);
}
