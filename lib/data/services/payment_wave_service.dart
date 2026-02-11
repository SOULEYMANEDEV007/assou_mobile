import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentWaveService {
  static const String _waveDeepLink = "wave://pay";
  static const List<String> _allowedDomains = [
    "pay.wave.com",
    "wave.com",
    "waveapps.com"
  ];

  /// Lance un paiement Wave avec gestion robuste des erreurs
  static Future<void> launchWavePayment({
    required BuildContext context,
    required String waveLaunchUrl,
    required String montantTotal,
  }) async {
    debugPrint('[WAVE] Initialisation du paiement de $montantTotal FCFA');
    debugPrint('[WAVE] URL reçue: $waveLaunchUrl');

    try {
      // 1. Validation de l'URL
      if (!_isValidWaveUrl(waveLaunchUrl)) {
        debugPrint('[WAVE] URL invalide');
        throw const FormatException("URL Wave invalide");
      }

      // 2. Conversion en deep link
      final deepLink = _convertToDeepLink(waveLaunchUrl);
      debugPrint('[WAVE] Deep link converti: $deepLink');

// 3. Tentative de lancement
      final launchSuccess = await _launchWave(
        context: context,
        webUrl: waveLaunchUrl,
        // deepLink parameter removed because _launchWave does not accept it
      );

      if (!launchSuccess) {
        debugPrint('[WAVE] Tous les modes de lancement ont échoué');
        await _showManualFallback(context, waveLaunchUrl, montantTotal);
      }
    } catch (e) {
      debugPrint('[WAVE] Erreur critique: ${e.toString()}');
      rethrow;
    }
  }

  /// Tente d'ouvrir Wave via deep link, avec fallback web
  static Future<bool> _launchWave({
    required BuildContext context,
    required String webUrl,
  }) async {
    try {
      // 1. Essayer d'abord avec le package Wave officiel
      // Try direct launch first - if Wave app is installed, it will handle the deep link
      try {
        final launchSuccess = await launchUrl(
          Uri.parse('wave://pay?${Uri.parse(webUrl).query}'),
          mode: LaunchMode.externalApplication,
        );
        if (launchSuccess) return true;
      } catch (e) {
        debugPrint('[WAVE] Deep link failed: $e');
      }

      // 2. Fallback: Intent Android explicite
      final intent = AndroidIntent(
        action: 'action_view',
        data: webUrl,
        package: 'com.wave.android',
      );
      try {
        await intent.launch();
        return true;
      } catch (_) {}

      // 3. Fallback standard
      return await launchUrl(
        Uri.parse(webUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Wave launch error: $e');
      return false;
    }
  }

  /// Valide que l'URL pointe bien vers un domaine Wave autorisé
  static bool _isValidWaveUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty &&
          _allowedDomains.any((domain) => uri.host.contains(domain));
    } catch (e) {
      debugPrint('[WAVE] Erreur de validation URL: ${e.toString()}');
      return false;
    }
  }

  /// Convertit une URL web en deep link Wave
  static Uri _convertToDeepLink(String webUrl) {
    try {
      final uri = Uri.parse(webUrl);
      return Uri.parse(
        webUrl.replaceFirst(uri.origin, _waveDeepLink),
      );
    } catch (e) {
      debugPrint('[WAVE] Erreur de conversion deep link: ${e.toString()}');
      return Uri.parse(_waveDeepLink);
    }
  }

  /// Affiche un fallback manuel avec option de copie
  static Future<void> _showManualFallback(
    BuildContext context,
    String url,
    String montant,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ouvrir Wave Manuellement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pour payer $montant FCFA:'),
            const SizedBox(height: 10),
            SelectableText(
              url,
              style: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié !')),
                );
              }
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}
