import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv/core/extensions/color_extension.dart';
import 'package:tv/core/pages/web_view/web_view_page.dart';
import 'package:tv/core/resources/color_constants.dart';
import 'package:tv/core/resources/string_constants.dart';

import 'core/resources/endpoints.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: StringConstants.kAppName,
        theme: ThemeData(
          primarySwatch: ColorConstants.kGreen.toMaterialColor(),
        ),
        home: WebViewPage(
          url: EndPoints.kBaseUrl,
          title: StringConstants.kAppName,
        ),
      ),
    );
  }
}
