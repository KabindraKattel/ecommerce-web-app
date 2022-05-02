import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StreamProvider<bool> watchConnectivityProvider = StreamProvider<bool>(
    (ref) => Connectivity()
        .onConnectivityChanged
        .map((event) => event == ConnectivityResult.none ? false : true));
