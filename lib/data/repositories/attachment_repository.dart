import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/attachments.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class AttachmentRepository {
  final Isar isar;

  AttachmentRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<AttachmentRead>> getAll() async {
    final List<Attachments> rows = await isar.attachments.where().findAll();
    rows.sort((a, b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((row) {
      return AttachmentRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<AttachmentRead?> getById(String id) async {
    final Attachments? row = await isar.attachments
        .filter()
        .attachmentIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    return AttachmentRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<List<AttachmentRead>> getByTransactionId(String transactionId) async {
    // Get the transaction to find its journal IDs
    final TransactionRepository txRepo = TransactionRepository(isar);
    final TransactionRead? transaction = await txRepo.getById(transactionId);
    
    if (transaction == null) {
      return <AttachmentRead>[];
    }
    
    // Extract all transaction journal IDs from the transaction splits
    final Set<String> journalIds = <String>{};
    for (final TransactionSplit split in transaction.attributes.transactions) {
      if (split.transactionJournalId != null) {
        journalIds.add(split.transactionJournalId!);
      }
    }
    
    if (journalIds.isEmpty) {
      return <AttachmentRead>[];
    }
    
    // Match attachments where attachableId matches any journal ID
    final List<AttachmentRead> all = await getAll();
    return all.where((attachment) {
      final String? attachableId = attachment.attributes.attachableId;
      return attachableId != null && journalIds.contains(attachableId);
    }).toList();
  }

  Future<void> upsertFromSync(AttachmentRead attachment) async {
    final DateTime? updatedAt = attachment.attributes.updatedAt;
    final DateTime now = _getNow();

    final Attachments? existing = await isar.attachments
        .filter()
        .attachmentIdEqualTo(attachment.id)
        .findFirst();

    if (existing != null) {
      existing
        ..data = jsonEncode(attachment.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;

      await isar.writeTxn(() async {
        await isar.attachments.put(existing);
      });
    } else {
      final Attachments row = Attachments()
        ..attachmentId = attachment.id
        ..data = jsonEncode(attachment.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;

      await isar.writeTxn(() async {
        await isar.attachments.put(row);
      });
    }
  }

  Future<void> upsertListFromSync(List<AttachmentRead> attachments) async {
    for (final AttachmentRead attachment in attachments) {
      await upsertFromSync(attachment);
    }
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final Attachments? existing = await isar.attachments
        .filter()
        .attachmentIdEqualTo(id)
        .findFirst();

    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.attachments.delete(existing.id);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'attachments'
      ..entityId = id
      ..operation = 'DELETE'
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }
}

