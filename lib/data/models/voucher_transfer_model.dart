import 'package:flutter/material.dart';
import 'user_model.dart';
import 'bon_achat_model.dart';

class VoucherTransfer {
  final int id;
  final int? senderId;
  final int? receiverId;
  final int paiementBonId;
  final String transferReference;
  final String? transferMessage;
  final String? recipientPhone; // For unregistered users
  final String status;
  final DateTime? transferredAt;
  final Map<String, dynamic>? transferMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final User? sender;
  final User? receiver;
  final Voucher? voucher;

  // Transfer status constants - IMPORTANT
  static const String STATUS_PENDING = 'pending';     // Transfer initiated, waiting
  static const String STATUS_COMPLETED = 'completed'; // Transfer completed successfully
  static const String STATUS_CANCELLED = 'cancelled'; // Transfer cancelled by user
  static const String STATUS_FAILED = 'failed';       // Transfer failed due to error

  VoucherTransfer({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.paiementBonId,
    required this.transferReference,
    this.transferMessage,
    this.recipientPhone,
    required this.status,
    this.transferredAt,
    this.transferMetadata,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.receiver,
    this.voucher,
  });

  // Status helper methods
  bool get isPending => status.toLowerCase() == STATUS_PENDING;
  bool get isCompleted => status.toLowerCase() == STATUS_COMPLETED;
  bool get isCancelled => status.toLowerCase() == STATUS_CANCELLED;
  bool get isFailed => status.toLowerCase() == STATUS_FAILED;

  String get statusText {
    switch (status.toLowerCase()) {
      case STATUS_PENDING:
        return 'En attente';
      case STATUS_COMPLETED:
        return 'Complété';
      case STATUS_CANCELLED:
        return 'Annulé';
      case STATUS_FAILED:
        return 'Échec';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case STATUS_PENDING:
        return Colors.orange;
      case STATUS_COMPLETED:
        return Colors.green;
      case STATUS_CANCELLED:
        return Colors.grey;
      case STATUS_FAILED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case STATUS_PENDING:
        return Icons.hourglass_empty;
      case STATUS_COMPLETED:
        return Icons.check_circle;
      case STATUS_CANCELLED:
        return Icons.cancel;
      case STATUS_FAILED:
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  factory VoucherTransfer.fromJson(Map<String, dynamic> json) {
    return VoucherTransfer(
      id: json['id'] ?? 0,
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      paiementBonId: json['paiement_bon_id'] ?? 0,
      transferReference: json['transfer_reference'] ?? '',
      transferMessage: json['transfer_message'],
      recipientPhone: json['recipient_phone'],
      status: json['transfer_status'] ?? json['status'] ?? 'unknown',
      transferredAt: json['transferred_at'] != null
          ? DateTime.parse(json['transferred_at'])
          : null,
      transferMetadata: json['transfer_metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      receiver: json['receiver'] != null ? User.fromJson(json['receiver']) : null,
      voucher: json['paiement_bon'] != null ? Voucher.fromJson(json['paiement_bon']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'paiement_bon_id': paiementBonId,
      'transfer_reference': transferReference,
      'transfer_message': transferMessage,
      'recipient_phone': recipientPhone,
      'status': status,
      'transferred_at': transferredAt?.toIso8601String(),
      'transfer_metadata': transferMetadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'paiement_bon': voucher?.toJson(),
    };
  }
}
