import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psy_fi/core/components/custom_button.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
class WifiAutoChecker extends StatefulWidget {
  final Widget child;
  const WifiAutoChecker({Key? key, required this.child}) : super(key: key);

  @override
  State<WifiAutoChecker> createState() => _WifiAutoCheckerState();
}

class _WifiAutoCheckerState extends State<WifiAutoChecker> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  Future<void> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      setState(() => _isConnected = result.isNotEmpty);
    } catch (_) {
      setState(() => _isConnected = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkInternetAccess();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      // This is now a List<ConnectivityResult>
      if (results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet)) {
        _checkInternetAccess();
      } else {
        setState(() => _isConnected = false);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override

Widget build(BuildContext context) {
  if (_isConnected) {
    return widget.child;
  } else {
    return NoInternetScreen(onRetrySuccess: () {
      setState(() {
        _isConnected = true;
      });
    });
  }
}

}


class NoInternetScreen extends StatefulWidget {
  final VoidCallback onRetrySuccess;

  const NoInternetScreen({super.key, required this.onRetrySuccess});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}


class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _retrying = false;

Future<void> _retryConnection() async {
  setState(() => _retrying = true);
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty) {
      widget.onRetrySuccess(); // go back to previous screen
    }
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Still no connection.")),
    );
  } finally {
    if (mounted) {
      setState(() => _retrying = false);
    }
  }
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Center(
        child: _retrying
            ? const  LoadingScreen(
        messages: [
          "We are here...",
          "Almost there...",
          "Hang tight...",
        ],
        progressColor: Colors.blue, // or your theme color
      )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    "No Internet Connection",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: "Retry",
                    onPressed: _retryConnection,
                  ),
                ],
              ),
      ),
    ),
  );
}

}
