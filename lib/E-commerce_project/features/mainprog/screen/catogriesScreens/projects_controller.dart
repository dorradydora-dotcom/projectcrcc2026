import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/main.dart';
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
          .from('user_top')
          .select()
          .eq('user_email', email)
          .limit(1);
      if (topRes.isNotEmpty) {
        hasAccess.value = true;
        accessLevel.value = 'top';
      } else {
        // Check user_others
        final othersRes = await client
            .from('user_crcc')
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
          .from('projects')
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
      await Supabase.instance.client.from('projects').insert(project.toJson());
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
          .from('projects')
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
      await Supabase.instance.client.from('projects').delete().eq('id', id);
      await fetchProjects();
      Get.snackbar('نجاح', 'تم حذف المشروع بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف المشروع');
    }
  }
}
