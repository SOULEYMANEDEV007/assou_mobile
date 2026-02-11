import 'package:ASSOU/data/models/gift_challenge_model.dart';
import 'package:ASSOU/providers/reward_provider.dart';
import 'package:ASSOU/widgets/custom_app_bar.dart';
import 'package:ASSOU/widgets/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';

class RecompensesPage extends StatefulWidget {
  final bool showBottomNav;

  const RecompensesPage({super.key, this.showBottomNav = true});

  @override
  State<RecompensesPage> createState() => _RecompensesPageState();
}

class _RecompensesPageState extends State<RecompensesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription? _milestoneSubscription;
  // late TabController _tabController; // Commenté car non utilisé

  @override
  void initState() {
    super.initState();
    print('DEBUG [RECOMPENSES] Page initialisée avec succès');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // _tabController = TabController(length: 3, vsync: this); // Commenté car non utilisé

    // Initialiser les données au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG [RECOMPENSES] Appel de RewardProvider.init()');
      final provider = context.read<RewardProvider>();
      provider.init();

      // Écouter les franchissements de paliers
      _milestoneSubscription = provider.milestoneStream.listen((event) {
        _showMilestoneUnlockedDialog(event);
      });
    });
  }

  void _showMilestoneUnlockedDialog(MilestoneEvent event) {
    if (!mounted) return;

    ToastHelper.showToast(
      context,
      title: "Palier Atteint !",
      message: event.message,
      type: ToastType.success,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _milestoneSubscription?.cancel();
    // _tabController.dispose(); // Commenté car non utilisé
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Récompenses ",
        showBackButton: true,
      ),
      body: Consumer<RewardProvider>(
        builder: (context, provider, child) {
          // Si on n'a absolument rien (même pas en cache) et que ça charge
          if (provider.isStatsLoading && provider.stats == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          return _buildChallengeTab(
              provider); // Retourne directement l'onglet Challenge
        },
      ),
    );
  }

  // Onglet principal du Challenge
  Widget _buildChallengeTab(RewardProvider provider) {
    final stats = provider.stats;
    if (stats == null) {
      return const Center(child: Text("Aucune donnée disponible"));
    }

    return SafeArea(
      child: Stack(
        children: [
          _buildBackgroundDecorations(),
          Positioned.fill(
            child: Column(
              children: [
                // Fixed Header with progress circle
                Container(
                  color: Colors.white.withOpacity(0.95),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(stats),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.refreshAll(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildRewardsPath(stats),
                          const SizedBox(height: 20),
                          //_buildBadgesSection(stats),
                          const SizedBox(height: 20),
                          _buildInfoMessage(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Décorations en arrière-plan (filigrane)
  Widget _buildBackgroundDecorations() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1, // Très léger pour ne pas gêner la lecture
        child: Image.asset(
          'assets/images/FondRecompenseAssou.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // En-tête avec le cercle de progression
  Widget _buildHeader(RewardStats stats) {
    final currentPoints = stats.pointsMensuels;
    final targetPoints = stats.monthlyGoal;
    final progress = (currentPoints / targetPoints).clamp(0.0, 1.0);

    return Column(
      children: [
        const Text(
          'Ton niveau actuel pour ce mois',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de fond gris
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 14,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                ),
              ),
              // Cercle de progression jaune
              Transform.rotate(
                angle: -math.pi / 2,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              // Texte central
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${math.min(currentPoints, targetPoints)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'sur $targetPoints pts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (stats.rank > 0) const SizedBox(height: 15),
        _buildMilestoneStatus(currentPoints),
      ],
    );
  }

  // Chemin des récompenses en zig-zag
  Widget _buildRewardsPath(RewardStats stats) {
    final currentPoints = stats.pointsMensuels;

    NodeStatus getStatus(int milestonePoints) {
      if (currentPoints >= milestonePoints) {
        // Liste des paliers fixes basés sur le design
        final milestones = [10, 50, 100, 150, 200, 250];
        int idx = milestones.indexOf(milestonePoints);
        if (idx == milestones.length - 1 ||
            currentPoints < milestones[idx + 1]) {
          return NodeStatus.active;
        }
        return NodeStatus.unlocked;
      }
      return NodeStatus.locked;
    }

    return SizedBox(
      height: 750,
      child: Stack(
        children: [
          // Ligne tracée entre les paliers
          Positioned.fill(
            child: CustomPaint(
              painter: PathPainter(currentPoints: currentPoints),
            ),
          ),
          // Les nœuds (paliers) positionnés
          _buildNode(
            top: 20,
            right: 40,
            points: 250,
            imagePath: 'assets/images/infini.png',
            status: getStatus(250),
          ),
          _buildNode(
            top: 140,
            left: 50,
            points: 200,
            imagePath: 'assets/images/coeur.png',
            status: getStatus(200),
          ),
          _buildNode(
            top: 270,
            right: 50,
            points: 150,
            imagePath: 'assets/images/amis.png',
            status: getStatus(150),
          ),
          _buildNode(
            top: 400,
            left: 50,
            points: 100,
            imagePath: 'assets/images/des-ballons.png',
            status: getStatus(100),
          ),
          _buildNode(
            top: 520,
            right: 55,
            points: 50,
            imagePath: 'assets/images/amis2.png',
            status: getStatus(50),
          ),
          _buildNode(
            top: 630,
            left: 50,
            points: 10,
            imagePath: 'assets/images/joie.png',
            status: getStatus(10),
            showConfetti: currentPoints >= 10 && currentPoints < 50,
          ),
        ],
      ),
    );
  }

  // Widget personnalisé pour chaque nœud du chemin
  Widget _buildNode({
    double? top,
    double? left,
    double? right,
    required int points,
    required String imagePath,
    required NodeStatus status,
    bool showConfetti = false,
  }) {
    final bool isUnlocked =
        status == NodeStatus.unlocked || status == NodeStatus.active;
    final bool isActive = status == NodeStatus.active;

    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de halo pour le nœud actif
              if (isActive)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC107).withOpacity(0.25),
                  ),
                ),
              // Conteneur de l'icône
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isUnlocked)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                  ],
                  border: Border.all(
                    color:
                        isActive ? const Color(0xFFFFC107) : Colors.transparent,
                    width: 3,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.5,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    color:
                        isUnlocked ? null : Colors.grey, // Grisé si verrouillé
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$points pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black87 : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour choisir l'icône de badge
  Widget _getBadgeIcon(String iconRef, bool isUnlocked) {
    IconData iconData = Icons.stars;
    if (iconRef == 'gift') iconData = Icons.card_giftcard;
    if (iconRef == 'star') iconData = Icons.star;
    if (iconRef == 'award') iconData = Icons.emoji_events;
    if (iconRef == 'trophy') iconData = Icons.workspace_premium;

    return Icon(iconData,
        color: isUnlocked ? Colors.amber : Colors.grey, size: 40);
  }

  // Informations explicatives
  Widget _buildInfoMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text.rich(
        TextSpan(
          text: 'Chaque fois que tu offres un bon Assou, tu gagnes entre ',
          style: TextStyle(color: Colors.black87, height: 1.5, fontSize: 13),
          children: [
            TextSpan(
              text: '10 et 20 pts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ' en fonction du montant du bon envoyé.\nTon objectif : atteindre ',
            ),
            TextSpan(
              text: '250 pts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ' chaque mois.\nPlus ton geste est généreux, plus tu progresses vite.',
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper: Build milestone status badge
  Widget _buildMilestoneStatus(int currentPoints) {
    String message;
    IconData icon;
    Color color;

    if (currentPoints >= 250) {
      message = '🎉 Sommet du Challenge !';
      icon = Icons.emoji_events;
      color = const Color(0xFFFFD700);
    } else if (currentPoints >= 200) {
      message = '⭐ Super Partageur';
      icon = Icons.star;
      color = const Color(0xFFFFC107);
    } else if (currentPoints >= 100) {
      message = '✨ Actif — tu illumines ta communauté !';
      icon = Icons.celebration;
      color = const Color(0xFFFFC107);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Énumération pour l'état d'un nœud du palier
enum NodeStatus {
  locked,
  unlocked,
  active,
}

// Peintre personnalisé pour dessiner le chemin en zig-zag
class PathPainter extends CustomPainter {
  final int currentPoints;

  PathPainter({required this.currentPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.grey.shade300
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFFFFC107)
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;

    // Définition des points du chemin (doit correspondre au placement des nœuds)
    final p10 = Offset(88, 680);
    final p50 = Offset(w - 90, 570);
    final p100 = Offset(88, 450);
    final p150 = Offset(w - 88, 320);
    final p200 = Offset(88, 190);
    final p250 = Offset(w - 78, 60);

    // Dessiner le chemin complet en gris
    path.moveTo(p10.dx, p10.dy);
    _drawCurve(path, p10, p50);
    _drawCurve(path, p50, p100);
    _drawCurve(path, p100, p150);
    _drawCurve(path, p150, p200);
    _drawCurve(path, p200, p250);
    canvas.drawPath(path, paint);

    // Dessiner la partie active en jaune
    final activePath = Path();
    activePath.moveTo(p10.dx, p10.dy);

    if (currentPoints >= 10) {
      if (currentPoints >= 50) {
        _drawCurve(activePath, p10, p50);
        if (currentPoints >= 100) {
          _drawCurve(activePath, p50, p100);
          if (currentPoints >= 150) {
            _drawCurve(activePath, p100, p150);
            if (currentPoints >= 200) {
              _drawCurve(activePath, p150, p200);
              if (currentPoints >= 250) {
                _drawCurve(activePath, p200, p250);
              } else {
                _drawPartialCurve(
                    activePath, p200, p250, (currentPoints - 200) / 50);
              }
            } else {
              _drawPartialCurve(
                  activePath, p150, p200, (currentPoints - 150) / 50);
            }
          } else {
            _drawPartialCurve(
                activePath, p100, p150, (currentPoints - 100) / 50);
          }
        } else {
          _drawPartialCurve(activePath, p50, p100, (currentPoints - 50) / 50);
        }
      } else {
        _drawPartialCurve(activePath, p10, p50, (currentPoints - 10) / 40);
      }
      canvas.drawPath(activePath, activePaint);
    }
  }

  // Trace une courbe cubique complète
  void _drawCurve(Path path, Offset start, Offset end) {
    final double controlPointDist = (end.dy - start.dy).abs() * 0.5;
    final cp1 = Offset(start.dx, start.dy - controlPointDist);
    final cp2 = Offset(end.dx, end.dy + controlPointDist);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
  }

  // Trace une partie de courbe proportionnellement à la progression
  void _drawPartialCurve(Path path, Offset start, Offset end, double t) {
    if (t <= 0) return;
    final double controlPointDist = (end.dy - start.dy).abs() * 0.5;
    final cp1 = Offset(start.dx, start.dy - controlPointDist);
    final cp2 = Offset(end.dx, end.dy + controlPointDist);

    // Algorithme de Casteljau pour interpoler la courbe de Bézier cubique
    for (double i = 0.05; i <= t.clamp(0.0, 1.0); i += 0.05) {
      final x = _bezierPoint(start.dx, cp1.dx, cp2.dx, end.dx, i);
      final y = _bezierPoint(start.dy, cp1.dy, cp2.dy, end.dy, i);
      path.lineTo(x, y);
    }
  }

  double _bezierPoint(double p0, double p1, double p2, double p3, double t) {
    return math.pow(1 - t, 3) * p0 +
        3 * math.pow(1 - t, 2) * t * p1 +
        3 * (1 - t) * math.pow(t, 2) * p2 +
        math.pow(t, 3) * p3;
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) =>
      oldDelegate.currentPoints != currentPoints;
}
