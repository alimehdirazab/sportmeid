// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportMeid',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child:  Center(
          child: Image(
            image: AssetImage('assets/images/appIcon.png'),
            width: 150,
            height: 150,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.sports,
                size: 150,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}

// Add the WelcomeView class
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1) Full-screen background GIF
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_welcome.gif', // Update with your asset path
              fit: BoxFit.cover,
            ),
          ),

          // 2) (Optional) semi-transparent overlay to darken
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // 3) Smoke GIF at the bottom
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/smoke_welcome.gif', // Update with your asset path
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          ),

          // 4) Content (title, subtitle, button)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 24),

                // Title
                Text(
                  'SPORT ME ID',
                  style: TextStyle(
                    fontSize: 66,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Blockletter',
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Connecting Athletes, Coaches, and Recruiters for Seamless Talent Discovery.',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),

                const Spacer(flex: 2),

                // Get Started button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFDDA027),
                          Color(0xFFCE9B2B),
                          Color(0xFFFEF48E),
                          Color(0xFFFFD046),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WebViewScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _requestPermissions();
  }

  // Future<void> _requestPermissions() async {
  //   await [
  //     Permission.camera,
  //     Permission.microphone,
  //     Permission.storage,
  //     Permission.manageExternalStorage,
  //   ].request();
  // }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      if (url.startsWith('blob:')) {
        // First try to get the blob data from our JavaScript mapping
        String script =
            '''
          (function() {
            if (window.blobToBase64Map && window.blobToBase64Map.has('$url')) {
              console.log('Found blob data in map for: $url');
              return window.blobToBase64Map.get('$url');
            }
            console.log('Blob not found in map, trying fetch...');
            return null;
          })();
        ''';

        var mappedResult = await webViewController?.evaluateJavascript(
          source: script,
        );

        if (mappedResult != null &&
            mappedResult is String &&
            mappedResult.isNotEmpty &&
            mappedResult != 'null') {
          Uint8List bytes = base64Decode(mappedResult);
          await _saveFile(bytes, filename);
          return;
        }

        // Fallback: try the original fetch method
        String fetchScript =
            '''
          (async function() {
            try {
              const response = await fetch('$url');
              const blob = await response.blob();
              return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = function() {
                  resolve(reader.result.split(',')[1]);
                };
                reader.onerror = reject;
                reader.readAsDataURL(blob);
              });
            } catch (error) {
              console.error('Blob fetch failed:', error);
              return null;
            }
          })();
        ''';

        var result = await webViewController?.evaluateJavascript(
          source: fetchScript,
        );
        if (result != null && result is String && result.isNotEmpty) {
          Uint8List bytes = base64Decode(result);
          await _saveFile(bytes, filename);
        } else {
          // Last resort: try canvas extraction
          String canvasScript = '''
            (function() {
              const canvases = document.querySelectorAll('canvas');
              if (canvases.length > 0) {
                try {
                  const canvas = canvases[canvases.length - 1];
                  const dataUrl = canvas.toDataURL('image/png');
                  return dataUrl.split(',')[1];
                } catch (e) {
                  console.log('Canvas extraction failed:', e);
                  return null;
                }
              }
              return null;
            })();
          ''';

          var canvasResult = await webViewController?.evaluateJavascript(
            source: canvasScript,
          );
          if (canvasResult != null &&
              canvasResult is String &&
              canvasResult.isNotEmpty &&
              canvasResult != 'null') {
            Uint8List bytes = base64Decode(canvasResult);
            await _saveFile(bytes, filename);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download failed: Unable to access file data'),
              ),
            );
          }
        }
      } else {
        // Handle regular URLs
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await _saveFile(response.bodyBytes, filename);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: HTTP ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download error: $e')));
    }
  }

  Future<void> _saveFile(Uint8List bytes, String filename) async {
    try {
      // Ensure filename is valid and unique
      String safeFilename = filename;
      if (safeFilename.isEmpty || safeFilename.toLowerCase() == 'unknown') {
        // Use a timestamp for uniqueness
        safeFilename = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      } else if (!safeFilename.toLowerCase().endsWith('.png')) {
        safeFilename = '$safeFilename.png';
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // iOS: Save to Documents/athlete/ and make it visible in Files app if Info.plist is set
        final docsDir = await getApplicationDocumentsDirectory();
        directory = Directory('${docsDir.path}/athlete');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      final file = File('${directory!.path}/$safeFilename');
      await file.writeAsBytes(bytes);

      // File saved successfully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: $safeFilename to ${directory.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save error: $e')));
    }
  }

  Future<void> _shareFile(String url, String filename) async {
    try {
      Uint8List? bytes;

      if (url.startsWith('blob:')) {
        String script =
            '''
          (function() {
            return new Promise((resolve, reject) => {
              fetch('$url')
                .then(response => response.blob())
                .then(blob => {
                  const reader = new FileReader();
                  reader.onload = function() {
                    resolve(reader.result.split(',')[1]);
                  };
                  reader.onerror = reject;
                  reader.readAsDataURL(blob);
                })
                .catch(reject);
            });
          })();
        ''';

        var result = await webViewController?.evaluateJavascript(
          source: script,
        );
        if (result != null && result is String) {
          bytes = base64Decode(result);
        }
      } else {
        // Handle regular URLs
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
        }
      }

      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'QR Code');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body:InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://sportmeid.mmcgbl.dev/auth/login'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              //mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useOnDownloadStart: true,
             // useShouldOverrideUrlLoading: true,
              allowFileAccess: true,
              allowContentAccess: true,
              allowUniversalAccessFromFileURLs: true,
              allowFileAccessFromFileURLs: true,
              supportMultipleWindows: true,
              cacheEnabled: false, // <--- This disables caching
              cacheMode: CacheMode.LOAD_DEFAULT,
              clearSessionCache: false,
            ),

            onWebViewCreated: (controller) {
              webViewController = controller;

              // Add JavaScript handlers for share functionality
              controller.addJavaScriptHandler(
                handlerName: 'shareHandler',
                callback: (args) async {
                  if (args.isNotEmpty) {
                    String url = args[0].toString();
                    String filename = args.length > 1
                        ? args[1].toString()
                        : 'qr_code.png';
                    await _shareFile(url, filename);
                  }
                },
              );

              // Add download handler for blob URLs
              controller.addJavaScriptHandler(
                handlerName: 'downloadHandler',
                callback: (args) async {
                  if (args.isNotEmpty) {
                    String base64Data = args[0].toString();
                    String filename = args.length > 1
                        ? args[1].toString()
                        : 'qr_code.png';

                    try {
                      Uint8List bytes = base64Decode(base64Data);
                      await _saveFile(bytes, filename);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download error: $e')),
                      );
                    }
                  }
                },
              );
            },
            onLoadStop: (controller, url) async {
              // Inject JavaScript to intercept download buttons and handle share API
              await controller.evaluateJavascript(
                source: '''
                if (!navigator.share) {
                  navigator.share = function(data) {
                    return new Promise((resolve, reject) => {
                      if (data.url) {
                        window.flutter_inappwebview.callHandler('shareHandler', data.url, 'qr_code.png');
                        resolve();
                      } else {
                        reject(new Error('No shareable content'));
                      }
                    });
                  };
                }

                // Store mapping from blob URL to base64 data
                window.blobToBase64Map = new Map();
                
                // Patch URL.createObjectURL to capture blob data immediately
                const originalCreateObjectURL = URL.createObjectURL;
                URL.createObjectURL = function(blob) {
                  const blobUrl = originalCreateObjectURL.call(this, blob);
                  console.log('Blob URL created:', blobUrl);
                  
                  // Store the blob data for this URL
                  if (blob instanceof Blob) {
                    const reader = new FileReader();
                    reader.onload = function() {
                      const base64 = reader.result.split(',')[1];
                      window.blobToBase64Map.set(blobUrl, base64);
                      console.log('Blob data mapped for:', blobUrl);
                    };
                    reader.readAsDataURL(blob);
                  }
                  
                  return blobUrl;
                };

                // Intercept ALL clicks on the page
                document.addEventListener('click', function(event) {
                  const target = event.target;
                  
                  // Check if this is a download-related element
                  const isDownloadButton = target.tagName === 'A' && target.hasAttribute('download') ||
                                         target.tagName === 'BUTTON' && (target.textContent || '').toLowerCase().includes('download') ||
                                         (target.className || '').toLowerCase().includes('download');
                  
                  if (isDownloadButton) {
                    console.log('Download button clicked:', target.tagName, target.textContent);
                    
                    // Look for blob URLs on the page
                    const blobLinks = document.querySelectorAll('a[href^="blob:"]');
                    
                    for (const link of blobLinks) {
                      const blobUrl = link.href;
                      if (window.blobToBase64Map.has(blobUrl)) {
                        console.log('Found mapped blob data for:', blobUrl);
                        event.preventDefault();
                        event.stopPropagation();
                        
                        const base64Data = window.blobToBase64Map.get(blobUrl);
                        const filename = link.download || 'qr_code.png';
                        
                        // Call Flutter with the stored base64 data
                        window.flutter_inappwebview.callHandler('downloadHandler', base64Data, filename);
                        return false;
                      }
                    }
                    
                    // If no blob found, try canvas extraction
                    const canvases = document.querySelectorAll('canvas');
                    if (canvases.length > 0) {
                      try {
                        console.log('Trying canvas extraction');
                        event.preventDefault();
                        event.stopPropagation();
                        
                        const canvas = canvases[canvases.length - 1];
                        const dataUrl = canvas.toDataURL('image/png');
                        const base64 = dataUrl.split(',')[1];
                        
                        window.flutter_inappwebview.callHandler('downloadHandler', base64, 'qr_code.png');
                        return false;
                      } catch (e) {
                        console.log('Canvas extraction failed:', e);
                      }
                    }
                    
                    console.log('No blob data or canvas found, allowing default behavior');
                  }
                }, true); // Use capture phase to intercept early
                
                console.log('Enhanced download interception ready with URL mapping');
              ''',
              );
            },
            // onConsoleMessage: (controller, consoleMessage) {

            // },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              String url = downloadStartRequest.url.toString();
              String filename =
                  downloadStartRequest.suggestedFilename ?? 'qr_code.png';

              await _downloadFile(url, filename);
            },
            onCreateWindow: (controller, createWindowAction) async {
              return true;
            },
            // onLoadError: (controller, url, code, message) {
            //   print('Load error: $code, $message');
            // },
            // onLoadHttpError: (controller, url, statusCode, description) {
            //   print('HTTP error: $statusCode, $description');
            // },
          ),
        
      ),
    );
  }
}
