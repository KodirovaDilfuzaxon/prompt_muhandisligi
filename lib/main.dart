// Prompt muhandisligi — ilmiy-metodik qöllanma (Android ilova)
// Qöllanma HTML’i ilova içida (assets/www) saqlanadi va internetsiz işlaydi.
// Flutter tomoni: orqaga tugmasi, taşqi havolalar, nusxalaş va status bar rangi.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

// Qöllanma palitrasi (HTML’dagi --surface va --bg qiymatlari bilan bir xil)
const Color _kunduzSirt = Color(0xFFFFFDF8);
const Color _tunSirt = Color(0xFF1C1F26);
const Color _oltin = Color(0xFFA8873A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ da ilova ekranning töliq maydonini egallaydi; çetlarni SafeArea boşqaradi
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const PromptIlova());
}

class PromptIlova extends StatelessWidget {
  const PromptIlova({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Prompt muhandisligi',
      debugShowCheckedModeBanner: false,
      home: QollanmaSahifasi(),
    );
  }
}

class QollanmaSahifasi extends StatefulWidget {
  const QollanmaSahifasi({super.key});

  @override
  State<QollanmaSahifasi> createState() => _QollanmaSahifasiState();
}

class _QollanmaSahifasiState extends State<QollanmaSahifasi> {
  late final WebViewController _web;
  bool _yuklandi = false;
  late bool _tungi;

  @override
  void initState() {
    super.initState();
    // Boşlanğiç tema — tizimnikidan; sahifa yuklangaç HTML aniq temani xabar qiladi
    _tungi = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_tungi ? _tunSirt : _kunduzSirt)
      ..enableZoom(false)
      ..addJavaScriptChannel('AppBridge', onMessageReceived: _xabarniQabulQil)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (soro) {
            final uri = Uri.tryParse(soro.url);
            // Ilova içidagi fayllar (file://) WebView’da qoladi, qolgan hammasi tizim brauzeriga
            if (uri != null && uri.scheme != 'file' && uri.scheme != 'about' && uri.scheme != 'data') {
              _tashqiOch(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _yuklandi = true);
          },
        ),
      )
      ..loadFlutterAsset('assets/www/index.html');

    // Android’ga xos sozlamalar
    final platforma = _web.platform;
    if (platforma is AndroidWebViewController) {
      // Tizim şrift ölçami qöllanmaning öz A/A/A tugmalari bilan ikki marta kattalaşmasin
      platforma.setTextZoom(100);
    }
  }

  // HTML’dan keladigan xabarlar: {"t":"open"|"copy"|"theme", ...}
  void _xabarniQabulQil(JavaScriptMessage xabar) {
    Map<String, dynamic> m;
    try {
      m = jsonDecode(xabar.message) as Map<String, dynamic>;
    } catch (_) {
      return; // notöğri formatdagi xabar e’tiborsiz qoldiriladi
    }
    switch (m['t']) {
      case 'open':
        final uri = Uri.tryParse('${m['u']}');
        if (uri != null) _tashqiOch(uri);
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: '${m['x'] ?? ''}'));
        break;
      case 'theme':
        final tungi = m['dark'] == true;
        if (tungi != _tungi && mounted) {
          setState(() => _tungi = tungi);
          _web.setBackgroundColor(tungi ? _tunSirt : _kunduzSirt);
        }
        break;
    }
  }

  // Faqat http, https, mailto va tel havolalarini taşqi ilovada oçamiz
  Future<void> _tashqiOch(Uri uri) async {
    const ruxsat = {'http', 'https', 'mailto', 'tel'};
    if (!ruxsat.contains(uri.scheme)) return;
    final oldi = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!oldi && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Havolani oçib bölmadi. Brauzer örnatilganini tekşiring.')),
      );
    }
  }

  // Orqaga tugmasi: avval qöllanma içida orqaga, boş sahifada — ilovadan çiqiş
  Future<void> _orqaga() async {
    var ichkarida = false;
    try {
      final natija = await _web.runJavaScriptReturningResult('window.appBack ? appBack() : false');
      ichkarida = natija == true || natija.toString() == 'true';
    } catch (_) {
      ichkarida = false;
    }
    if (!ichkarida) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final sirt = _tungi ? _tunSirt : _kunduzSirt;
    final ikonlar = _tungi ? Brightness.light : Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _orqaga();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: ikonlar,
          statusBarBrightness: _tungi ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: sirt,
          systemNavigationBarIconBrightness: ikonlar,
        ),
        child: Scaffold(
          backgroundColor: sirt,
          body: SafeArea(
            child: Stack(
              children: [
                WebViewWidget(controller: _web),
                // Yuklanguncha oq “çaqnaş” örniga qöllanma rangidagi ekran
                IgnorePointer(
                  ignoring: _yuklandi,
                  child: AnimatedOpacity(
                    opacity: _yuklandi ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      color: sirt,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: _oltin),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
