// lib/features/sync/fitbit_authorize_url.dart
import 'package:cloud_functions/cloud_functions.dart' as cf;
import 'package:flutter/material.dart';

/// Builds the Fitbit authorize URL with a server-signed `state`.
///
/// fitbitCallback only accepts state issued by fitbitOAuthStateCall, which ties
/// it to the signed-in Firebase user. Returns null (after showing a snackbar)
/// if the state can't be fetched.
Future<Uri?> buildFitbitAuthorizeUrl(
  BuildContext context, {
  required String clientId,
  required String redirectUri,
  required List<String> scopes,
}) async {
  try {
    final res = await cf.FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('fitbitOAuthStateCall')
        .call<dynamic>();
    final state = Uri.encodeComponent((res.data as Map)['state'] as String);
    final scope = Uri.encodeComponent(scopes.join(' '));
    final redirect = Uri.encodeComponent(redirectUri);
    return Uri.parse(
      'https://www.fitbit.com/oauth2/authorize'
          '?response_type=code'
          '&client_id=$clientId'
          '&redirect_uri=$redirect'
          '&scope=$scope'
          '&state=$state',
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start Fitbit sign-in. Please try again.')),
      );
    }
    return null;
  }
}
