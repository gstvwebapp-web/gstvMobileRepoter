import 'dart:io';
import 'package:get/get.dart';
import '../../data/models/clip_model.dart';
import '../../data/models/video_project_model.dart';
import '../../data/repository/project_repository_impl.dart';
import '../../core/services/storage_service.dart';
import '../controllers/editor_controller.dart';

/// Binding that bridges gstv_admin's navigation (which passes a [File])
/// with the [EditorController] (which expects an [EditorArgs] containing
/// a project ID).
///
/// When the route is opened with a [File] argument, this binding:
/// 1. Ensures GetStorage boxes are initialised for the editor's persistence.
/// 2. Creates a new [VideoProjectModel] with a single [ClipModel] from the
///    video file, saves it, and then instantiates [EditorController] with the
///    project's ID.
class VideoEditorBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure storage boxes are bound (idempotent if already done).
    StorageService.instance.bindBoxes();

    final arguments = Get.arguments;
    late final String projectId;

    if (arguments is File) {
      // Create a new project from the video file.
      final project = _createProjectFromFile(arguments);
      projectId = project.id;
    } else if (arguments is EditorArgs) {
      projectId = arguments.projectId;
    } else if (arguments is String) {
      // Assume it's a project ID string.
      projectId = arguments;
    } else {
      // Fallback: create an empty project.
      final project = VideoProjectModel(title: 'Untitled project');
      final repo = ProjectRepositoryImpl();
      repo.saveProject(project);
      projectId = project.id;
    }

    final args = EditorArgs(projectId: projectId);
    Get.lazyPut<EditorController>(() => EditorController(args: args));
  }

  /// Creates a [VideoProjectModel] with a single clip from the given video
  /// [file]. We use a generous default duration; the EditorController will
  /// re-initialise the player and read the real duration on onInit.
  VideoProjectModel _createProjectFromFile(File file) {
    final fileName = file.path.split('/').last.split('.').first;

    final clip = ClipModel(
      sourcePath: file.path,
      originalDuration: const Duration(seconds: 30),
    );

    final project = VideoProjectModel(
      title: fileName.isNotEmpty ? fileName : 'Untitled project',
      clips: [clip],
    );

    // Persist immediately so EditorController.onInit can load it.
    final repo = ProjectRepositoryImpl();
    repo.saveProject(project);

    return project;
  }
}
