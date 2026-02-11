// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class BuyScannerPage extends StatefulWidget {
//   final VoidCallback? onBackPressed;
//
//   const BuyScannerPage({Key? key, this.onBackPressed}) : super(key: key);
//
//   @override
//   State<BuyScannerPage> createState() => _BuyScannerPageState();
// }
//
// class _BuyScannerPageState extends State<BuyScannerPage> {
//   bool _hasPermission = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _requestPermission();
//   }
//
//   Future<void> _requestPermission() async {
//     final status = await Permission.camera.request();
//     setState(() {
//       _hasPermission = status.isGranted;
//     });
//
//     if (!status.isGranted) {
//       _showPermissionDialog();
//     }
//   }
//
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text("Permission requise"),
//         content: const Text(
//             "Veuillez autoriser l'accès à la caméra pour scanner un code QR."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Fermer"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             child: const Text("Paramètres"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_hasPermission) {
//       return Scaffold(
//         backgroundColor: const Color(0xFFF8FAFC),
//         body: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text("Initialisation du scanner..."),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Scanner view
//             MobileScanner(
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 if (barcodes.isNotEmpty) {
//                   final String? code = barcodes.first.rawValue;
//                   if (code != null) {
//                     // Use callback if provided, otherwise fall back to Navigator.pop
//                     if (widget.onBackPressed != null) {
//                       widget.onBackPressed!();
//                     } else {
//                       Navigator.pop(context);
//                     }
//                   }
//                 }
//               },
//             ),
//             // Overlay with instructions
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withOpacity(0.7),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       onPressed: () {
//                         // Use callback if provided, otherwise fall back to Navigator.pop
//                         if (widget.onBackPressed != null) {
//                           widget.onBackPressed!();
//                         } else {
//                           Navigator.pop(context);
//                         }
//                       },
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     ),
//                     const Expanded(
//                       child: Text(
//                         "Scanner QR Code",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     const SizedBox(width: 48), // Balance the back button
//                   ],
//                 ),
//               ),
//             ),
//             // Bottom instruction
//             Positioned(
//               bottom: 60,
//               left: 20,
//               right: 20,
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                     ),
//                   ],
//                 ),
//                 child: const Text(
//                   "Scannez le QR code du magasin pour utiliser un de vos bons",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF1E293B),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
