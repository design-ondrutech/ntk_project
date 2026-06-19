import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

class GraphQLService {
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(true);
  String? _token;
  String _languageCode = 'en'; // Default to English
  late GraphQLClient _client;
  late String _endpoint;

  GraphQLService() {
    _endpoint = 'https://naam-tamilar-katchi-5.onrender.com/graphQL';
    _updateClient();
  }

  void setToken(String? token) {
    _token = token;
    _updateClient();
  }

  void setLanguage(String languageCode) {
    _languageCode = languageCode;
    _updateClient();
  }

  void _updateClient() {
    final httpLink = HttpLink(
      _endpoint,
      defaultHeaders: {
        'Accept': 'application/json',
        'Accept-Language': _languageCode,
      },
    );

    Link link = httpLink;

    if (_token != null) {
      final authLink = AuthLink(getToken: () async => 'Bearer $_token');
      link = authLink.concat(httpLink);
    }

    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.networkOnly),
      ),
    );
  }

  GraphQLClient get client => _client;

  /// Performs a GraphQL query using raw HTTP to bypass graphql_flutter's
  /// internal 5-second timeout limitation.
  Future<QueryResult> performQuery(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final filteredVariables = Map<String, dynamic>.from(variables ?? {})
      ..removeWhere((key, value) => value == null);

    final opts = QueryOptions(
      document: gql(query),
      variables: filteredVariables,
      fetchPolicy: FetchPolicy.networkOnly,
    );

    return _rawRequest(
      document: query,
      variables: filteredVariables,
      options: opts,
    );
  }

  /// Performs a GraphQL mutation using raw HTTP.
  Future<QueryResult> performMutation(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    final filteredVariables = Map<String, dynamic>.from(variables ?? {})
      ..removeWhere((key, value) => value == null);

    final opts = QueryOptions(
      document: gql(mutation),
      variables: filteredVariables,
      fetchPolicy: FetchPolicy.networkOnly,
    );

    return _rawRequest(
      document: mutation,
      variables: filteredVariables,
      options: opts,
    );
  }

  Future<QueryResult> _rawRequest({
    required String document,
    required Map<String, dynamic> variables,
    required QueryOptions options,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': _languageCode,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final body = jsonEncode({
        'query': document,
        if (variables.isNotEmpty) 'variables': variables,
      });

      final requestFuture = http.post(Uri.parse(_endpoint), headers: headers, body: body);
      // Catch and ignore late errors from the original future to prevent unhandled exceptions after timeout
      requestFuture.ignore();
      
      final response = await requestFuture.timeout(const Duration(seconds: 60));

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final snippet = response.body.length > 100 ? response.body.substring(0, 100) : response.body;
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(message: 'Server Error (HTTP ${response.statusCode}). Backend returned HTML instead of JSON: $snippet...'),
            ],
          ),
        );
      }

      final errors = json['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          exception: OperationException(
            graphqlErrors: errors
                .map(
                  (e) => GraphQLError(
                    message: e['message'] as String? ?? 'Unknown error',
                  ),
                )
                .toList(),
          ),
        );
      }

      connectionStatus.value = true;
      return QueryResult(
        options: options,
        source: QueryResultSource.network,
        data: json['data'] as Map<String, dynamic>?,
      );
    } on TimeoutException {
      connectionStatus.value = false;
      throw const NetworkException('No Internet Connection. Please check your network and try again.');
    } catch (e, stack) {
      if (_isNetworkError(e)) {
        connectionStatus.value = false;
        throw const NetworkException('No Internet Connection. Please check your network and try again.');
      }
      connectionStatus.value = true;
      return QueryResult(
        options: options,
        source: QueryResultSource.network,
        exception: OperationException(
          linkException: UnknownException(e, stack),
        ),
      );
    }
  }

  bool _isNetworkError(dynamic error) {
    final errStr = error.toString().toLowerCase();
    return errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception') ||
        errStr.contains('connection failed') ||
        errStr.contains('connection refused') ||
        errStr.contains('network') ||
        errStr.contains('timed out') ||
        errStr.contains('timeoutexception') ||
        errStr.contains('host lookup') ||
        errStr.contains('unreachable') ||
        errStr.contains('handshake');
  }
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}
