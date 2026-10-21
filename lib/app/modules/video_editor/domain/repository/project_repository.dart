import '../../data/models/video_project_model.dart';

/// Persistence contract for [VideoProjectModel]s — autosave, load, list,
/// delete. Implemented by [ProjectRepositoryImpl] over [StorageService].
abstract class ProjectRepository {
  Future<void> saveProject(VideoProjectModel project);
  VideoProjectModel? loadProject(String projectId);
  List<VideoProjectModel> listProjects();
  Future<void> deleteProject(String projectId);
}
