import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorldController extends GetxController {
  final RxString initialUrlworld = RxString('');
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxDouble progress = 0.0.obs;
  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    fetchUrl();
  }

  @override
  void onClose() {
    webViewController?.dispose();
    super.onClose();
  }

  Future<void> fetchUrl() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final response = await Supabase.instance.client
          .from('world_table')
          .select('link_string')
          .eq('url_name', 'url_1')
          .limit(1)
          .single();

      final url = response['link_string'] as String?;

      if (url == null || url.isEmpty) {
        hasError.value = true;
        isLoading.value = false;
        Get.snackbar('خطأ', 'الرابط غير متاح حالياً');
        return;
      }

      initialUrlworld.value = url;
      hasError.value = false;
      isLoading.value = true; // Still loading until the webview finishes

      if (webViewController != null) {
        await webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(url)),
        );
      }
    } catch (e) {
      hasError.value = true;
      isLoading.value = false;
      Get.snackbar('خطأ', 'فشل في جلب الرابط من الخادم');
    }
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    if (initialUrlworld.value.isNotEmpty) {
      controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(initialUrlworld.value),
        ),
      );
    }
  }

  void onLoadStop() {
    isLoading.value = false;
    hasError.value = false;
  }

  void onLoadError() {
    isLoading.value = false;
    hasError.value = true;
    Get.snackbar('خطأ', 'فشل تحميل الخريطة');
  }

  void onProgressChanged(int p) {
    progress.value = p / 100;
  }
}
