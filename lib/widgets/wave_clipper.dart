import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Commencer en haut à gauche
    path.lineTo(0, 0);

    // Descendre le long du côté gauche
    path.lineTo(0, size.height - 80);

    // Première courbe (gauche vers centre)
    var firstControlPoint = Offset(size.width * 0.25, size.height - 20);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Deuxième courbe (centre vers droite) - SYMÉTRIQUE
    var secondControlPoint = Offset(size.width * 0.75, size.height - 20);
    var secondEndPoint = Offset(size.width, size.height - 80);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Remonter le long du côté droit
    path.lineTo(size.width, 0);

    // Fermer le chemin
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
