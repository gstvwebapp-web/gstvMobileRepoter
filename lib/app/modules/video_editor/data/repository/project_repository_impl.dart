import '../../core/services/storage_service.dart';
import '../../domain/repository/project_repository.dart';
import '../models/video_project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({StorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  @override
  Future<void> saveProject(VideoProjectModel project) async {
    project.updatedAt = DateTime.now();
    _storage.saveProjectJson(project.id, project.toJson());
  }

  @override
  VideoProjectModel? loadProject(String projectId) {
    final json = _storage.readProjectJson(projectId);
    if (json == null) return null;
    return VideoProjectModel.fromJson(json);
  }

  @override
  List<VideoProjectModel> listProjects() {
    final projects = _storage.allProjects.values
        .whereType<Map<String, dynamic>>()
        .map(VideoProjectModel.fromJson)
        .toList();
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _storage.deleteProject(projectId);
  }
}
