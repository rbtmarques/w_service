// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library w_service.src.generic.interceptors.csrf_interceptor;

import 'dart:async';

import 'package:w_service/w_service.dart';
import 'package:w_transport/w_transport.dart';

List<String> csrfRequired = ['DELETE', 'PATCH', 'POST', 'PUT'];

/// An interceptor that handles one form of protection against
/// Cross-Site Request Forgery by setting a CSRF token in a header
/// on every outgoing request and by updating the current CSRF token
/// by parsing incoming response headers.
///
/// This interceptor is designed for HTTP requests and only has an
/// effect when used with the [w_service.HttpProvider].
///
/// By default, the CSRF token header used is "x-xsrf-token".
/// This can be overridden upon construction:
///
///     var csrfInterceptor = new CsrfInterceptor(header: 'x-csrf-token');
///
/// The CSRF token header will only be set if it is not already.
/// In other words, setting the CSRF token manually on a request
/// will override this interceptor's functionality.
class CsrfInterceptor extends Interceptor {
  /// Get and set the CSRF token to be set on every outgoing request.
  String token = '';

  /// CSRF header name - "x-xsrf-token" by default.
  final String _header;

  /// Construct a new [CsrfInterceptor] instance. By default,
  /// the CSRF header used is "x-xsrf-token".
  ///
  /// To use a different header, specify one during construction:
  ///
  ///     var csrfInterceptor = new CsrfInterceptor(header: 'x-csrf-token');
  CsrfInterceptor({String header: 'x-xsrf-token'})
      : super('csrf'),
        _header = header;

  /// Intercepts an outgoing request and sets the appropriate header
  /// with the latest CSRF token.
  @override
  Future<Context> onOutgoing(Provider provider, Context context) async {
    // Inject CSRF token into headers.
    if (context is HttpContext) {
      if (context.request.headers.containsKey(_header)) {
        if (context.request.headers[_header] == null) {
          throw new ArgumentError('CSRF header value can not be null');
        }
      } else if (csrfRequired.contains(context.method)) {
        context.request.headers[_header] = token;
      }
    }
    return context;
  }

  /// Intercepts an incoming response and checks the headers for an
  /// updated CSRF token. If found, the updated token is stored for
  /// use on all future requests.
  @override
  Future<Context> onIncoming(Provider provider, Context context) async {
    // Retrieve next token from response headers.
    if (context is HttpContext) {
      _updateToken(context.response);
    }
    return context;
  }

  /// Intercepts an incoming failed response and checks the headers
  /// for an updated CSRF token. If found, the updated token is stored
  /// for use on all future requests.
  @override
  Future<Context> onIncomingRejected(
      Provider provider, Context context, Object error) async {
    // Retrieve next token from response headers.
    if (context is HttpContext) {
      _updateToken(context.response);
    }
    throw error;
  }

  /// Update the CSRF token from a response if one is available.
  _updateToken(WResponse response) {
    if (response == null) return;
    if (response.headers.containsKey(_header) &&
        response.headers[_header] != null &&
        response.headers[_header] != '') {
      token = response.headers[_header];
    }
  }
}
