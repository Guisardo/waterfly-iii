import 'package:logging/logging.dart';
import '../../generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';

/// Adapter for Firefly III API client to work with sync manager.
class FireflyApiAdapter {
  final Logger _logger = Logger('FireflyApiAdapter');
  final FireflyIii apiClient;

  FireflyApiAdapter(this.apiClient);

  /// Create a transaction
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Creating transaction via API');
    
    final TransactionStore store = TransactionStore(
      transactions: <TransactionSplitStore>[
        TransactionSplitStore(
          type: TransactionTypeProperty.withdrawal,
          amount: data['amount']?.toString() ?? '0',
          description: data['description'] as String? ?? '',
          date: DateTime.parse(data['date'] as String? ?? DateTime.now().toIso8601String()),
          sourceId: data['source_id'] as String?,
          destinationId: data['destination_id'] as String?,
          categoryId: data['category_id'] as String?,
        ),
      ],
    );

    final response = await apiClient.v1TransactionsPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create transaction: ${response.error}');
    }

    final transaction = response.body!.data;
    return {
      'id': transaction.id,
      'type': transaction.type,
      'attributes': transaction.attributes.toJson(),
    };
  }

  /// Update a transaction
  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating transaction $id via API');
    
    final update = TransactionUpdate(
      transactions: [
        TransactionSplitUpdate(
          amount: data['amount']?.toString(),
          description: data['description'] as String?,
          date: data['date'] != null ? DateTime.parse(data['date'] as String) : null,
          sourceId: data['source_id'] as String?,
          destinationId: data['destination_id'] as String?,
          categoryId: data['category_id'] as String?,
        ),
      ],
    );

    final response = await apiClient.v1TransactionsIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update transaction: ${response.error}');
    }

    final transaction = response.body!.data;
    return {
      'id': transaction.id,
      'type': transaction.type,
      'attributes': transaction.attributes.toJson(),
    };
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    _logger.fine('Deleting transaction $id via API');
    
    final response = await apiClient.v1TransactionsIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete transaction: ${response.error}');
    }
  }

  /// Get a transaction
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    _logger.fine('Getting transaction $id via API');
    
    final response = await apiClient.v1TransactionsIdGet(id: id);
    
    if (!response.isSuccessful || response.body == null) {
      return null;
    }

    final transaction = response.body!.data;
    return {
      'id': transaction.id,
      'type': transaction.type,
      'attributes': transaction.attributes.toJson(),
    };
  }
}
