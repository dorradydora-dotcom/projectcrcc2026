import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Mapscreen extends StatelessWidget {
  const Mapscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExternalLinkHomePage();
  }
}

class ExternalLinkHomePage extends StatefulWidget {
  const ExternalLinkHomePage({super.key});

  @override
  State<ExternalLinkHomePage> createState() => _ExternalLinkHomePageState();
}

class _ExternalLinkHomePageState extends State<ExternalLinkHomePage> {
  String? _initialUrl;
  bool _isLoading = true;
  bool _hasError = false;
  double _progress = 0.0;
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  @override
  void dispose() {
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
          .eq('url_name', 'url_3')
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
        _initialUrl = url;
        _hasError = false;
        _isLoading = true;
      });
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
    if (!mounted || !context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: Appfontstring.ChangaLight,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _fetchUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.backgroundColor,
      appBar: const CustomAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExplanationText(),
            Expanded(
              child: _buildMapContent(),
            ),
          ],
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildExplanationText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Appcolors.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Appcolors.primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: Appcolors.primaryColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '-- تعرض الخريطة البيانات التالية :',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontFamily: Appfontstring.ChangaLight,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
                Icons.bolt, 'مسارات خطوط الطاقة على جميع مستويات الجهد'),
            _buildBulletPoint(Icons.link, 'محطات الربط بجميع الدول'),
            _buildBulletPoint(
                Icons.warning, 'تداخلات الخطوط بين التضاربس المختلفة'),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 3),
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  'جميع البيانات محدثة بالاقمار الصناعية كل 3 شهور',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: Appcolors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Appcolors.textPrimary,
                fontFamily: Appfontstring.ChangaLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    if (_hasError || _initialUrl == null || _initialUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Appcolors.primaryColor.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Progress bar only if loading (moved logic here for consistency)
            if (_progress > 0 && _progress < 1)
              SizedBox(
                height: 3,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Appcolors.textSecondary.withOpacity(0.3),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Appcolors.primaryColor),
                ),
              ),
            // Removed unnecessary flex:2; default Expanded is flex:1
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(_initialUrl!)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  cacheEnabled: true,
                  allowsBackForwardNavigationGestures: true,
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  // Added for performance: enable hardware acceleration and limit zoom
                  allowsInlineMediaPlayback: true,
                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,
                  supportZoom: false, // Disable zoom if not needed for map
                ),
                pullToRefreshController: _pullToRefreshController ??=
                    PullToRefreshController(
                  settings: PullToRefreshSettings(
                    color: Appcolors.primaryColor,
                  ),
                  onRefresh: () async {
                    await _webViewController?.reload();
                  },
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  // Load URL immediately if already fetched (handles edge case)
                  if (_initialUrl != null) {
                    controller.loadUrl(
                        urlRequest: URLRequest(url: WebUri(_initialUrl!)));
                  }
                },
                onLoadStop: (controller, url) {
                  if (mounted) {
                    setState(() => _isLoading = false);
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
                    setState(() => _progress = progress / 100);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return RefreshIndicator(
      onRefresh: _fetchUrl,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: Colors.red, size: 64),
                ),
                const SizedBox(height: 16),
                const Text(
                  'فشل تحميل الخريطة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Appcolors.textPrimary,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Appcolors.backgroundColor
          .withOpacity(0.8), // Reduced opacity for better overlay feel
      child: Column(
        children: [
          // Progress bar integrated into overlay
          if (_initialUrl != null)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Appcolors.textSecondary.withOpacity(0.3),
                valueColor:
                    AlwaysStoppedAnimation<Color>(Appcolors.primaryColor),
              ),
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
                  const SizedBox(height: 16),
                  Text(
                    _initialUrl == null
                        ? 'جاري جلب الرابط...'
                        : 'جاري تحميل الخريطة...',
                    style: const TextStyle(
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
