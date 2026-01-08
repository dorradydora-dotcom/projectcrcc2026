import 'dart:ui';

import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExternalLinkHomePage2();
  }
}

class ExternalLinkHomePage2 extends StatefulWidget {
  const ExternalLinkHomePage2({super.key});

  @override
  State<ExternalLinkHomePage2> createState() => _ExternalLinkHomePageState2();
}

class _ExternalLinkHomePageState2 extends State<ExternalLinkHomePage2> {
  String? initialUrlworld;
  bool _isLoading = true;
  bool _hasError = false;
  double _progress = 0.0;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  @override
  void dispose() {
    _webViewController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUrl() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await Supabase.instance.client
          .from('world_table')
          .select('link_string')
          .eq('url_name', 'url_1')
          .limit(1)
          .single();

      final url = response['link_string'] as String?;
      if (!mounted) return;

      if (url == null || url.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _showErrorSnackBar('الرابط غير متاح حالياً');
        return;
      }

      if (!mounted) return;
      setState(() {
        initialUrlworld = url;
        _hasError = false;
        _isLoading = true;
      });

      // Load the URL if the WebView controller is already available
      if (_webViewController != null && mounted) {
        await _webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(url)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _showErrorSnackBar('فشل في جلب الرابط من الخادم');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _fetchUrl,
        ),
      ),
    );
  }

  Future<bool> _handleBackNavigation() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      if (canGoBack) {
        await _webViewController!.goBack();
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Appcolors.backgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Appcolors.primaryColor, Appcolors.backgroundColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Appcolors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'متوسط استهلاك بلـدان العالم و انبعاث الكربون',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Appcolors.textPrimary),
              onPressed: _fetchUrl,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Description container
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Appcolors.backgroundColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Appcolors.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                ':  تعرض الخريطة البيانات التالية\n'
                ' متوسط استهلاك الدول من الطاقه  *\n'
                ' الطاقة المنقولة بين بعض الدول *\n'
                ' نسبة انبعاثات الكربون *\n'
                '  نسبة الطاقة المتجددة من إجمالي الطاقة المنتجة *',
                style: TextStyle(
                  fontSize: 14,
                  color: Appcolors.textPrimary,
                  fontFamily: Appfontstring.ChangaLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Expanded map container
            Expanded(
              child: Stack(
                children: [
                  _hasError
                      ? _buildErrorWidget()
                      : InAppWebView(
                          initialUrlRequest: null,
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                              javaScriptEnabled: true,
                              cacheEnabled: true,
                              supportZoom: false,
                              verticalScrollBarEnabled: false,
                              horizontalScrollBarEnabled: false,
                              mediaPlaybackRequiresUserGesture: false,
                            ),
                          ),
                          onWebViewCreated: (controller) {
                            _webViewController = controller;
                            // Load URL if already fetched
                            if (initialUrlworld != null) {
                              controller.loadUrl(
                                urlRequest: URLRequest(
                                  url: WebUri(initialUrlworld!),
                                ),
                              );
                            }
                          },
                          onLoadStop: (controller, url) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                _hasError = false;
                              });
                            }
                          },
                          onLoadError: (controller, url, code, message) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                _hasError = true;
                              });
                              _showErrorSnackBar('فشل تحميل الخريطة');
                            }
                          },
                          onProgressChanged: (controller, progress) {
                            if (mounted) {
                              setState(() {
                                _progress = progress / 100;
                              });
                            }
                          },
                        ),
                  if (_isLoading && !_hasError) _buildLoadingWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'فشل تحميل الخريطة',
              style: TextStyle(
                fontSize: 16,
                color: Appcolors.textPrimary,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchUrl,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.primaryColor,
                foregroundColor: Appcolors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Appcolors.backgroundColor.withOpacity(0.95),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            backgroundColor: Appcolors.textSecondary.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Appcolors.primaryColor),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCube(
                    color: Appcolors.primaryColor,
                    size: 50,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل الخريطة...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Appcolors.textPrimary,
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
