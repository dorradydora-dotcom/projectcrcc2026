import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectsController extends GetxController {
  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasAccess = false.obs;
  final RxString accessLevel = 'none'.obs;

  @override
  void onInit() {
    super.onInit();
    checkAccessAndFetch();
  }

  Future<void> checkAccessAndFetch() async {
    isLoading.value = true;
    try {
      final email = Get.find<AuthService>().getCurrentUserEmail();
      if (email == null) {
        hasAccess.value = false;
        return;
      }

      final client = Supabase.instance.client;

      // Check user_top
      final topRes = await client
          .from(AppConstants.tableUserTop)
          .select()
          .eq('user_email', email)
          .limit(1);
      if (topRes.isNotEmpty) {
        hasAccess.value = true;
        accessLevel.value = 'top';
      } else {
        // Check user_others
        final othersRes = await client
            .from(AppConstants.tableUserCrcc)
            .select()
            .eq('user_email', email)
            .limit(1);
        if (othersRes.isNotEmpty) {
          hasAccess.value = true;
          accessLevel.value = 'crcc';
        }
      }

      if (hasAccess.value) {
        await fetchProjects();
      }
    } catch (e) {
      debugPrint('Error checking access');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProjects() async {
    try {
      final response = await Supabase.instance.client
          .from(AppConstants.tableProjects)
          .select()
          .order('name', ascending: true);

      projects.assignAll((response as List<dynamic>)
          .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
          .toList());
    } catch (e) {
      debugPrint('Error fetching projects');
    }
  }

  Future<void> addProject(ProjectModel project) async {
    try {
      await Supabase.instance.client
          .from(AppConstants.tableProjects)
          .insert(project.toJson());
      await fetchProjects();
      Get.back();
      Get.snackbar('نجاح', 'تم إضافة المشروع بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إضافة المشروع');
    }
  }

  Future<void> updateProject(String id, ProjectModel project) async {
    try {
      await Supabase.instance.client
          .from(AppConstants.tableProjects)
          .update(project.toJson())
          .eq('id', id);
      await fetchProjects();
      Get.back();
      Get.snackbar('نجاح', 'تم تحديث المشروع بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث المشروع');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await Supabase.instance.client
          .from(AppConstants.tableProjects)
          .delete()
          .eq('id', id);
      await fetchProjects();
      Get.snackbar('نجاح', 'تم حذف المشروع بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف المشروع');
    }
  }
}
