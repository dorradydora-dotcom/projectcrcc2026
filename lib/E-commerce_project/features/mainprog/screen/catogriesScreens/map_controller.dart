import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxDouble progress = 0.0.obs;
  final RxnString initialUrl = RxnString();

  // WebView Controllers
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;

  @override
  void onInit() {
    super.onInit();
    fetchUrl();
  }

  Future<void> fetchUrl() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final response = await _supabase
          .from('world_table')
          .select('link_string')
          .eq('url_name', 'url_3')
          .limit(1)
          .single();

      final url = response['link_string'] as String?;

      if (url == null || url.isEmpty) {
        hasError.value = true;
        Get.snackbar(
          'تنبيه',
          'الرابط غير متاح حالياً',
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        initialUrl.value = url;
        // If webview is already created, load the url
        if (webViewController != null) {
          webViewController!.loadUrl(
            urlRequest: URLRequest(url: WebUri(url)),
          );
        }
      }
    } catch (e) {
      hasError.value = true;
      Get.snackbar(
        'خطأ',
        'فشل في جلب البيانات من الخادم',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void updateProgress(double value) {
    progress.value = value;
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    if (initialUrl.value != null) {
      controller.loadUrl(
        urlRequest: URLRequest(url: WebUri(initialUrl.value!)),
      );
    }
  }

  void reload() {
    webViewController?.reload();
  }
}
