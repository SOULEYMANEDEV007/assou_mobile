import 'package:ASSOU/utils/logger.dart';
import 'package:ASSOU/widgets/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/services/user_service.dart';
import '../../../data/services/voucher_service.dart';

class UseScannerPage extends StatefulWidget {
  final String idPaiementBon;
  const UseScannerPage({super.key, required this.idPaiementBon});

  @override
  State<UseScannerPage> createState() => _UseScannerPageState();
}

class _UseScannerPageState extends State<UseScannerPage> {
  bool _isProcessing = false;
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Future<void> _onQrDetected(String codeBoutique) async {
    if (_isProcessing || !mounted) return;

    AppLogger.info('QR Code detected: $codeBoutique', 'SCANNER_PAGE');

    setState(() => _isProcessing = true);
    _cameraController.stop();

    try {
      String? token = await UserService.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez vous reconnecter")),
        );
        Navigator.pop(context);
        return;
      }

      final ApiResponse<void> response = await VoucherService.useVoucher(
        token: token,
        codeBoutique: codeBoutique,
        slugBonPaiement: widget.idPaiementBon,
      );

      if (!mounted) return;

      if (response.success) {
        if (!mounted) return;

        // Afficher un dialogue de succès au lieu d'un toast
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de succès
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Message de succès
                    const Text(
                      'Utilisation du bon\neffectuée avec succès ✅',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Bouton OK
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacementNamed(context, "/home");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ToastHelper.showToast(
          context,
          title: "Utilisation du bon",
          message: "Erreur lors de l'utilisation du bon ❌",
          type: ToastType.error,
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(
        context,
        title: "Utilisation du bon",
        message: "Erreur lors de l'utilisation du bon ❌",
        type: ToastType.error,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/bons");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double boxSize = 250;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Position du carré au centre (en coordonnées écran)
          final left = (screenWidth - boxSize) / 2;
          final top = (screenHeight - boxSize) / 2;
          final right = left + boxSize;
          final bottom = top + boxSize;

          return Stack(
            children: [
              // 📷 Caméra
              MobileScanner(
                controller: _cameraController,
                onDetect: (capture) {
                  final rawValue = capture.barcodes.first.rawValue;
                  final barcode = capture.barcodes.first;

                  if (rawValue != null && mounted && !_isProcessing) {
                    final corners = barcode.corners;

                    // SOLUTION: Simplifier la détection
                    // Option 1: Scanner dans toute la zone (plus fiable)
                    if (corners.isNotEmpty) {
                      // Calculer le centre en coordonnées caméra
                      double centerX = 0;
                      double centerY = 0;

                      for (var corner in corners) {
                        centerX += corner.dx;
                        centerY += corner.dy;
                      }

                      centerX /= corners.length;
                      centerY /= corners.length;

                      // Convertir les coordonnées caméra vers écran
                      final size = capture.size;
                      if (size != null && size.width > 0 && size.height > 0) {
                        // Ratio de conversion
                        final scaleX = screenWidth / size.width;
                        final scaleY = screenHeight / size.height;

                        final screenX = centerX * scaleX;
                        final screenY = centerY * scaleY;

                        // Vérifier si dans la zone
                        if (screenX >= left &&
                            screenX <= right &&
                            screenY >= top &&
                            screenY <= bottom) {
                          _onQrDetected(rawValue);
                        }
                      } else {
                        // Si pas de size ou size invalide, scanner quand même car le QR est là
                        _onQrDetected(rawValue);
                      }
                    } else {
                      // Pas de coins détectés, scanner quand même
                      _onQrDetected(rawValue);
                    }
                  }
                },
              ),

              // 🟦 Overlay noir avec découpe
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ScannerOverlayPainter(
                      scanAreaWidth: boxSize,
                      scanAreaHeight: boxSize,
                      borderRadius: 24.0,
                    ),
                  ),
                ),
              ),

              // 📝 Texte d'instruction
              const Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Text(
                  "Placez le QR code dans le carré",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // ⏳ Overlay de chargement
              if (_isProcessing)
                const ModalBarrier(dismissible: false, color: Colors.black87),
              if (_isProcessing)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        "Traitement en cours...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// 🎨 CustomPainter pour créer l'overlay avec découpe
class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaWidth;
  final double scanAreaHeight;
  final double borderRadius;

  ScannerOverlayPainter({
    required this.scanAreaWidth,
    required this.scanAreaHeight,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final left = (size.width - scanAreaWidth) / 2;
    final top = (size.height - scanAreaHeight) / 2;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanArea = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight),
      Radius.circular(borderRadius),
    );

    path.addRRect(scanArea);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawRRect(scanArea, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
