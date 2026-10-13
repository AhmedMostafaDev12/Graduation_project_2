import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n/app_localizations.dart';

/// Tests replace the camera surface, while using the real screen/controller.
typedef QrScannerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onSerial,
);
final qrScannerBuilderProvider = Provider<QrScannerBuilder>(
  (ref) =>
      (context, onSerial) => GlassesQrScanner(onSerial: onSerial),
);

class GlassesQrScanner extends StatefulWidget {
  const GlassesQrScanner({super.key, required this.onSerial});
  final ValueChanged<String> onSerial;
  static String? serialFrom(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final serial = barcode.rawValue?.trim();
      if (barcode.format != BarcodeFormat.qrCode ||
          serial == null ||
          serial.isEmpty) {
        continue;
      }
      // The agreed case QR contains a plain serial, not JSON or a URL.
      if (serial.startsWith('{') ||
          serial.startsWith('[') ||
          (Uri.tryParse(serial)?.hasScheme ?? false)) {
        continue;
      }
      return serial;
    }
    return null;
  }

  @override
  State<GlassesQrScanner> createState() => _GlassesQrScannerState();
}

class _GlassesQrScannerState extends State<GlassesQrScanner> {
  bool _delivered = false;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    // The plugin owns its controller: it stops/resumes with app lifecycle and
    // disposes the camera when this surface is removed. Images are not returned.
    return MobileScanner(
      onDetect: (capture) {
        if (_delivered) return;
        final serial = GlassesQrScanner.serialFrom(capture);
        if (serial == null) return;
        _delivered = true;
        widget.onSerial(serial);
      },
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            error.errorCode == MobileScannerErrorCode.permissionDenied
                ? s.pairCameraPermission
                : s.pairCameraUnavailable,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
