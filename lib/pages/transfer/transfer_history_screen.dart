import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/voucher_transfer_model.dart';
import '../../data/services/voucher_transfer_service.dart';
import '../../data/services/user_service.dart';
import '../../utils/logger.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  List<VoucherTransfer> _transfers = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransferData();
  }

  Future<void> _loadTransferData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        setState(() {
          _error = 'Utilisateur non authentifié';
          _isLoading = false;
        });
        return;
      }

      final transfers = await VoucherTransferService.getTransferHistory(
        token: token,
        limit: 100,
      );
      final stats = await VoucherTransferService.getTransferStats(token: token);

      setState(() {
        _transfers = transfers;
        _stats = stats;
        _isLoading = false;
      });

      AppLogger.info('Loaded ${transfers.length} transfers and stats: $stats', 'TRANSFER_HISTORY_SCREEN');
    } catch (e) {
      AppLogger.error('Failed to load transfer data', 'TRANSFER_HISTORY_SCREEN', e);
      setState(() {
        _error = 'Erreur lors du chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Transferts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransferData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransferData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransferData,
                  child: Column(
                    children: [
                      // Statistics Cards
                      _buildStatsCards(),

                      // Transfer List
                      Expanded(
                        child: _transfers.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Aucun transfert trouvé',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Vos transferts de bons apparaîtront ici',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _transfers.length,
                                itemBuilder: (context, index) {
                                  final transfer = _transfers[index];
                                  return _buildTransferCard(transfer);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Envoyés',
              _stats['totalSent'] ?? 0,
              Colors.blue,
              Icons.call_made,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Reçus',
              _stats['totalReceived'] ?? 0,
              Colors.green,
              Icons.call_received,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'En attente',
              (_stats['pendingSent'] ?? 0) + (_stats['pendingReceived'] ?? 0),
              Colors.orange,
              Icons.hourglass_empty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferCard(VoucherTransfer transfer) {
    // For now, assume current user ID - you'll need to implement getCurrentUserId()
    // This is a placeholder - you should get the current user ID from your auth service
    const isReceived = false; // TODO: Implement proper user ID checking

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transfer.statusColor.withOpacity(0.1),
          child: Icon(
            isReceived ? Icons.call_received : Icons.call_made,
            color: transfer.statusColor,
          ),
        ),
        title: Text(
          isReceived
              ? 'De: ${transfer.sender?.fullName ?? 'Utilisateur'}'
              : 'À: ${transfer.receiver?.fullName ?? transfer.recipientPhone ?? 'Destinataire'}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bon: ${transfer.voucher?.bonAchat?.libelle ?? 'N/A'}'),
            Text('Montant: ${transfer.voucher?.montantBon ?? 0} FCFA'),
            if (transfer.transferMessage?.isNotEmpty == true)
              Text(
                'Message: "${transfer.transferMessage}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: transfer.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transfer.statusText,
                style: TextStyle(
                  color: transfer.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM').format(transfer.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showTransferDetails(transfer),
      ),
    );
  }

  void _showTransferDetails(VoucherTransfer transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Détails du Transfert',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow('Référence', transfer.transferReference),
                _buildDetailRow('Statut', transfer.statusText),
                _buildDetailRow('Date', DateFormat('dd/MM/yyyy à HH:mm').format(transfer.createdAt)),
                
                if (transfer.sender != null)
                  _buildDetailRow('Expéditeur', transfer.sender!.fullName),
                if (transfer.receiver != null)
                  _buildDetailRow('Destinataire', transfer.receiver!.fullName),
                if (transfer.recipientPhone != null)
                  _buildDetailRow('Téléphone destinataire', transfer.recipientPhone!),
                  
                if (transfer.voucher != null) ...[
                  _buildDetailRow('Montant bon', '${transfer.voucher!.montantBon} FCFA'),
                  if (transfer.voucher!.bonAchat != null)
                    _buildDetailRow('Description', transfer.voucher!.bonAchat!.libelle),
                ],
                
                if (transfer.transferMessage?.isNotEmpty == true)
                  _buildDetailRow('Message', transfer.transferMessage!),
                  
                if (transfer.transferredAt != null)
                  _buildDetailRow('Transféré le', DateFormat('dd/MM/yyyy à HH:mm').format(transfer.transferredAt!)),
                  
                const SizedBox(height: 20),
                
                // Cancel button for pending transfers
                if (transfer.isPending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelTransfer(transfer),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Annuler le transfert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTransfer(VoucherTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le transfert'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce transfert ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await UserService.getAuthToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non authentifié')),
          );
        }
        return;
      }

      await VoucherTransferService.cancelTransfer(
        token: token,
        transferReference: transfer.transferReference,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Transfert annulé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTransferData(); // Refresh data
      }
    } catch (e) {
      AppLogger.error('Failed to cancel transfer', 'TRANSFER_HISTORY_SCREEN', e);
    }
  }
}
