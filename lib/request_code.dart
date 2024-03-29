import 'dart:async';
import 'package:flutter/material.dart';

import 'request/authorization_request.dart';
import 'model/config.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RequestCode {
  final Config _config;
  final AuthorizationRequest _authorizationRequest;

  String? _code;

  RequestCode(Config config)
      : _config = config,
        _authorizationRequest = AuthorizationRequest(config);
  Future<String?> requestCode() async {
    final urlParams = _constructUrlParams();

    var controller = WebViewController()
      ..loadRequest(Uri.parse('${_authorizationRequest.url}?$urlParams'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return _navigationDelegate(request);
          },
        ),
      );
    _code = null;
    var webView = WebViewWidget(controller: controller

        // initialUrl: '${_authorizationRequest.url}?$urlParams',
        // javascriptMode: JavascriptMode.unrestricted,
        // navigationDelegate: _navigationDelegate,
        );
    await _config.navigatorKey.currentState!.push(MaterialPageRoute(
        builder: (context) => Scaffold(
              body: SafeArea(child: webView),
            )));
    return _code;
  }

  FutureOr<NavigationDecision> _navigationDelegate(NavigationRequest request) {
    var uri = Uri.parse(request.url);

    if (uri.queryParameters['error'] != null) {
      _config.navigatorKey.currentState!.pop();
    }

    if (uri.queryParameters['code'] != null) {
      _code = uri.queryParameters['code'];
      _config.navigatorKey.currentState!.pop();
    }
    return NavigationDecision.navigate;
  }

  Future<void> clearCookies() async {
    await WebViewCookieManager().clearCookies();
  }

  String _constructUrlParams() => _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params.forEach((String key, String value) => queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    return queryParams.join('&');
  }
}
