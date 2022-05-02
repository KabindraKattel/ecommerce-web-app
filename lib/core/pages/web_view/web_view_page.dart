import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv/core/exceptions/exceptions.dart';
import 'package:tv/core/extensions/color_extension.dart';
import 'package:tv/core/utils/web_resource_error_message.dart';
import 'package:tv/core/widgets/error_msg_snack_bar.dart';
import 'package:tv/core/widgets/my_error.dart';
import 'package:tv/main.dart';
import 'package:tv/store/providers.dart';

class WebViewPage extends ConsumerStatefulWidget {
  final String url;
  final String title;

  WebViewPage({
    required this.url,
    required this.title,
  }) : super(key: UniqueKey());

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends ConsumerState<WebViewPage> {
  InAppWebViewController? _webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
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
      ));

  late PullToRefreshController pullToRefreshController;
  double progress = 0;
  String? error;

  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        if (Platform.isAndroid) {
          _webViewController?.reload();
        }
      },
    );
  }

  @override
  void dispose() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(watchConnectivityProvider, (previous, next) {
      next.maybeWhen(
          data: (hasConnection) async {
            if (!hasConnection) {
              scaffoldMessengerKey.currentState?.showSnackBar(
                  ErrorMsgSnackBar.buildInfiniteDuration(
                      message: const NetworkException().message));
            } else {
              await pullToRefreshController.beginRefreshing();
              previous?.whenData((hadConnection) {
                if (!hadConnection && error != null && progress == 1.0) {
                  error = null;
                }
              });
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
        if (_webViewController == null) {
          return true;
        } else if (await _webViewController!.canGoBack() &&
            !await _webViewController!.isLoading()) {
          _webViewController!.goBack();
          debugPrint(
              "Back Navigated to ${_webViewController?.getUrl().toString()}");
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: FutureBuilder<Widget>(
            future: _buildLeadingButton(context),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return Container();
              }
            },
          ),
          actions: [
            FutureBuilder<Widget>(
              future: _buildRefreshButton(context),
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
          index: progress < 1
              ? error != null
                  ? 2
                  : 1
              : error != null
                  ? 2
                  : 0,
          children: [
            _buildInAppWebView(),
            Center(child: CircularProgressIndicator(value: progress)),
            MyErrorWidget(
                error: error,
                onRetry: () async {
                  await _webViewController?.reload();
                }),
          ],
        ),
      ),
    );
  }

  InAppWebView _buildInAppWebView() {
    return InAppWebView(
      key: _key,
      gestureRecognizers: Set()
        ..add(Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer())),
      initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
      initialOptions: options,
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      androidOnPermissionRequest: (controller, origin, resources) async {
        return PermissionRequestResponse(
            resources: resources,
            action: PermissionRequestResponseAction.GRANT);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
      onLoadStop: (controller, url) async {
        debugPrint("Navigated to $url");
        await pullToRefreshController.endRefreshing();
      },
      onLoadError: (controller, url, code, message) {
        pullToRefreshController.endRefreshing();
        setState(() {
          error = Platform.isAndroid
              ? AndroidWebResourceErrorMessage(code).getMessage()
              : const OtherException().message;
        });
      },
      onProgressChanged: (controller, progress) {
        if (progress == 100) {
          pullToRefreshController.endRefreshing();
        }
        setState(() {
          this.progress = progress / 100;
        });
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (kDebugMode) {
          print(consoleMessage);
        }
      },
    );
  }

  Future<Widget> _buildRefreshButton(BuildContext context) async {
    if (_webViewController != null && !await _webViewController!.isLoading()) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        color: Theme.of(context).primaryColor.getForegroundColor(),
        onPressed: () => _webViewController?.reload(),
      );
    } else {
      return Container();
    }
  }

  Future<Widget> _buildLeadingButton(BuildContext context) async {
    if (Navigator.canPop(context)) {
      return BackButton(
        color: Theme.of(context).primaryColor.getForegroundColor(),
        onPressed: () => Navigator.of(context).pop(),
      );
    } else if (_webViewController != null &&
        await _webViewController!.canGoBack() &&
        !await _webViewController!.isLoading()) {
      return BackButton(
        color: Theme.of(context).primaryColor.getForegroundColor(),
        onPressed: () => _webViewController?.goBack(),
      );
    } else {
      return Container();
    }
  }
}
