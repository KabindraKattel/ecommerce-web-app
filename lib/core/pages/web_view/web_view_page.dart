import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tv/core/exceptions/exceptions.dart';
import 'package:tv/core/extensions/color_extension.dart';
import 'package:tv/core/utils/web_resource_error_message.dart';
import 'package:tv/core/widgets/error_msg_snack_bar.dart';
import 'package:tv/core/widgets/my_error.dart';
import 'package:tv/main.dart';
import 'package:tv/store/providers.dart';

class WebViewPage extends HookConsumerWidget {
  final String url;
  final String title;
  late PullToRefreshController pullToRefreshController;
  final InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      useOnDownloadStart: true,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  final TextEditingController urlController = TextEditingController();

  final _key = GlobalKey();

  WebViewPage({
    required this.url,
    required this.title,
  }) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _webViewController = useState<InAppWebViewController?>(null);
    final _webView = useState<InAppWebView?>(null);
    final loading = useState<bool>(true);
    final error = useState<String?>(null);
    pullToRefreshController = useMemoized(() => PullToRefreshController(
          onRefresh: () async {
            if (Platform.isAndroid) {
              await reload(_webViewController, loading, error);
            }
          },
        ));
    final progress = useState<double>(0);
    _webView.value ??=
        _buildInAppWebView(ref, _webViewController, loading, error, progress);
    ref.listen<AsyncValue<bool>>(watchConnectivityProvider, (previous, next) {
      next.maybeWhen(
          data: (hasConnection) async {
            if (!hasConnection) {
              if (loading.value == true) {
                error.value = const NetworkException().message;
              }
              scaffoldMessengerKey.currentState?.showSnackBar(
                  ErrorMsgSnackBar.buildInfiniteDuration(
                      message: const NetworkException().message));
            } else {
              await reload(_webViewController, loading, error);
              scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            }
          },
          error: (_, __) {
            scaffoldMessengerKey.currentState?.showSnackBar(
                ErrorMsgSnackBar.buildInfiniteDuration(
                    message: const OtherException().message));
          },
          orElse: () {});
    });
    return WillPopScope(
      onWillPop: () async {
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

        if (_webViewController.value == null) {
          return true;
        } else if (await _webViewController.value!.canGoBack() &&
            !await _webViewController.value!.isLoading()) {
          _webViewController.value!.goBack();
          debugPrint(
              "Back Navigated to ${_webViewController.value?.getUrl().toString()}");
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor:
                    Theme.of(context).primaryColor.getForegroundColor(),
                selectionColor: Theme.of(context)
                    .primaryColor
                    .getForegroundColor()
                    .getForegroundColor(),
                selectionHandleColor: Theme.of(context)
                    .primaryColor
                    .getForegroundColor()
                    .getForegroundColor(),
              ),
            ),
            child: TextField(
              style: TextStyle(
                  color: Theme.of(context).primaryColor.getForegroundColor()),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor.getForegroundColor(),
                ),
              ),
              controller: urlController,
              keyboardType: TextInputType.url,
              onSubmitted: (value) {
                var url = Uri.tryParse(value);
                url ??= Uri.parse("https://www.google.com/search?q=" + value);
                _webViewController.value
                    ?.loadUrl(urlRequest: URLRequest(url: url));
              },
            ),
          ),
          leading: FutureBuilder<Widget>(
            future: _buildLeadingButton(
                context, _webViewController, error, loading),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return Container();
              }
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                urlController.text = url;
                _webViewController.value?.loadUrl(
                    urlRequest: URLRequest(url: Uri.parse(urlController.text)));
              },
              icon: const Icon(Icons.link),
              tooltip: "DEFAULT URL",
            ),
            FutureBuilder<Widget>(
              future: _buildRefreshButton(
                  context, _webViewController, loading, error),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                } else {
                  return Container();
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: loading.value
              ? error.value != null
                  ? 2
                  : 1
              : error.value != null
                  ? 2
                  : 0,
          children: [
            _webView.value!,
            Center(
                child: CircularProgressIndicator(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.4),
                    value: progress.value)),
            MyErrorWidget(
                error: error.value,
                onRetry: () async {
                  await reload(_webViewController, loading, error);
                }),
          ],
        ),
      ),
    );
  }

  InAppWebView _buildInAppWebView(
      WidgetRef ref,
      ValueNotifier<InAppWebViewController?> _webviewController,
      ValueNotifier<bool> loading,
      ValueNotifier<String?> error,
      ValueNotifier<double> progressScale) {
    return InAppWebView(
      key: _key,
      gestureRecognizers: Set()
        ..add(Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer())),
      initialUrlRequest: URLRequest(url: Uri.parse(url)),
      initialOptions: options,
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        loading.value = true;
        _webviewController.value ??= controller;
      },
      androidOnPermissionRequest: (controller, origin, resources) async {
        return PermissionRequestResponse(
            resources: resources,
            action: PermissionRequestResponseAction.GRANT);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
      onLoadStart: (controller, url) async {
        loading.value = true;
        urlController.text = url?.toString() ?? '';
      },
      onLoadStop: (controller, url) async {
        debugPrint("Navigated to $url");
        await pullToRefreshController.endRefreshing();
        loading.value = false;
      },
      onTitleChanged: (controller, title) {},
      onLoadHttpError: (controller, url, code, message) {
        pullToRefreshController.endRefreshing();
        loading.value = false;
        error.value = Platform.isAndroid
            ? AndroidWebResourceErrorMessage(code).getMessage()
            : const OtherException().message;
      },
      onLoadError: (controller, url, code, message) {
        pullToRefreshController.endRefreshing();
        loading.value = false;
        error.value = Platform.isAndroid
            ? AndroidWebResourceErrorMessage(code).getMessage()
            : const OtherException().message;
      },
      onProgressChanged: (controller, progress) {
        if (progress == 100) {
          pullToRefreshController.endRefreshing();
          loading.value = false;
        } else {
          loading.value = true;
        }
        progressScale.value = progress / 100;
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (kDebugMode) {
          print(consoleMessage);
        }
      },
    );
  }

  Future<Widget> _buildRefreshButton(
      BuildContext context,
      ValueNotifier<InAppWebViewController?> _webViewController,
      ValueNotifier<bool> loading,
      ValueNotifier<String?> error) async {
    if (_webViewController.value != null) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        color: Theme.of(context).primaryColor.getForegroundColor(),
        onPressed: () async => await reload(_webViewController, loading, error),
      );
    } else {
      return Container();
    }
  }

  Future<void>? reload(
      ValueNotifier<InAppWebViewController?> _webViewController,
      ValueNotifier<bool> loading,
      ValueNotifier<String?> error) async {
    if (_webViewController.value != null) {
      if (error.value == null) {
        loading.value = true;

        await _webViewController.value!.reload();
      } else {
        error.value = null;
        loading.value = true;
        var recentUrl = await _webViewController.value!.getOriginalUrl();
        await _webViewController.value!.loadUrl(
            urlRequest: URLRequest(
          url: recentUrl,
        ));
      }
    }

    return Future.value();
  }

  Future<Widget> _buildLeadingButton(
      BuildContext context,
      ValueNotifier<InAppWebViewController?> _webViewController,
      ValueNotifier<String?> error,
      ValueNotifier<bool> loading) async {
    if (Navigator.canPop(context)) {
      return BackButton(
        color: Theme.of(context).primaryColor.getForegroundColor(),
        onPressed: () => Navigator.of(context).pop(),
      );
    } else if (_webViewController.value != null &&
        await _webViewController.value!.canGoBack()) {
      return BackButton(
        color: Theme.of(context).primaryColor.getForegroundColor(),
        onPressed: () {
          loading.value = true;
          _webViewController.value
              ?.goBack()
              .then((value) => error.value = null);
        },
      );
    } else {
      return Container();
    }
  }
}
