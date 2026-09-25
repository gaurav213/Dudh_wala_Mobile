import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin wrappers around `url_launcher` for call / maps / navigate actions.
class LaunchHelpers {
  const LaunchHelpers._();

  static Future<void> call(BuildContext context, String? phoneNumber) async {
    final digits = (phoneNumber ?? '').trim();
    if (digits.isEmpty) {
      _notify(context, 'No phone number on file.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    await _launch(context, uri, failureMessage: 'Could not start a call.');
  }

  static Future<void> copyText(BuildContext context, String? text) async {
    final value = (text ?? '').trim();
    if (value.isEmpty) {
      _notify(context, 'Nothing to copy.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) _notify(context, 'Copied.');
  }

  /// Opens a maps app for an exact [latitude]/[longitude] pin when available,
  /// otherwise falls back to a text [address] search.
  static Future<void> openMap(
    BuildContext context, {
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final query = address?.trim();
    final hasPin = latitude != null && longitude != null;
    if ((query == null || query.isEmpty) && !hasPin) {
      _notify(context, 'No address on file.');
      return;
    }

    if (hasPin) {
      await navigate(
        context,
        latitude: latitude,
        longitude: longitude,
        label: query,
      );
      return;
    }

    final label = Uri.encodeComponent(query!);
    final geoUri = Uri.parse('geo:0,0?q=$label');
    if (await canLaunchUrl(geoUri)) {
      await _launch(context, geoUri, failureMessage: 'Could not open maps.');
      return;
    }

    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$label',
    );
    await _launch(context, webUri, failureMessage: 'Could not open maps.');
  }

  /// Prefer Apple Maps on iOS, Google Maps / geo URI elsewhere, with web fallback.
  static Future<void> navigate(
    BuildContext context, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final name = Uri.encodeComponent(
        (label ?? 'Delivery').trim().isEmpty ? 'Delivery' : label!.trim());

    final candidates = <Uri>[];
    if (!kIsWeb && Platform.isIOS) {
      candidates.add(
        Uri.parse(
          'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
        ),
      );
    }
    candidates.add(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'
        '&destination_place_id=&travelmode=driving',
      ),
    );
    candidates.add(
        Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($name)'));
    candidates.add(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      ),
    );

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (ok) return;
        }
      } catch (_) {
        // try next
      }
    }
    if (context.mounted) _notify(context, 'Could not open maps.');
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri, {
    required String failureMessage,
  }) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _notify(context, failureMessage);
    } catch (_) {
      if (context.mounted) _notify(context, failureMessage);
    }
  }

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
