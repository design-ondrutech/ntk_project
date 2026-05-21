import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

class GraphQLService {
  String? _token;
  late GraphQLClient _client;
  late String _endpoint;

  GraphQLService() {
    String host = '127.0.0.1';
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // 10.0.2.2 = Android emulator only
        // Change to your PC's local IP when using a real device on the same WiFi
        host = '10.0.2.2'; // Android emulator → maps to host PC localhost
      }
    } catch (_) {}

    _endpoint = 'http://$host:4000/graphql';
    _updateClient();
  }

  void setToken(String? token) {
    _token = token;
    _updateClient();
  }

  void _updateClient() {
    final httpLink = HttpLink(
      _endpoint,
      defaultHeaders: {'Accept': 'application/json'},
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
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final body = jsonEncode({
        'query': document,
        if (variables.isNotEmpty) 'variables': variables,
      });

      final response = await http
          .post(Uri.parse(_endpoint), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
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

      return QueryResult(
        options: options,
        source: QueryResultSource.network,
        data: json['data'] as Map<String, dynamic>?,
      );
    } on TimeoutException {
      return QueryResult(
        options: options,
        source: QueryResultSource.network,
        exception: OperationException(
          linkException: UnknownException(
            Exception('Request timed out. Check your network connection.'),
            StackTrace.current,
          ),
        ),
      );
    } catch (e, stack) {
      return QueryResult(
        options: options,
        source: QueryResultSource.network,
        exception: OperationException(
          linkException: UnknownException(e, stack),
        ),
      );
    }
  }
}
