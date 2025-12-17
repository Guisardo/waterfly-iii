import 'package:chopper/chopper.dart' show Response;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/bill_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/widgets/entity_select_dialog.dart';

/// Shows a dialog to select a bill.
///
/// This is a convenience function that uses [EntitySelectDialog] configured
/// for bill selection. It returns the selected [BillRead] or null
/// if cancelled.
///
/// Example:
/// ```dart
/// final bill = await showBillDialog(
///   context: context,
///   currentBill: existingBill,
/// );
/// ```
Future<BillRead?> showBillDialog({
  required BuildContext context,
  BillRead? currentBill,
}) {
  // ignore: unused_local_variable
  final Logger log = Logger('BillDialog');

  return showDialog<BillRead>(
    context: context,
    builder: (BuildContext dialogContext) => EntitySelectDialog<BillRead>(
      config: EntitySelectConfig<BillRead>(
        icon: Icons.calendar_today,
        title: S.of(context).transactionDialogBillTitle,
        labelText: S.of(context).transactionDialogBillTitle,
        clearButtonText: S.of(context).transactionDialogBillNoBill,
        initialValue: currentBill,
        initialDisplayText: currentBill?.attributes.name,
        emptyResultFactory: () => BillRead(
          type: 'bill',
          id: '0',
          attributes: BillProperties(
            name: '',
            amountMin: '',
            amountMax: '',
            date: DateTime.now(),
            repeatFreq: BillRepeatFrequency.swaggerGeneratedUnknown,
          ),
        ),
        resultFactory: (AutocompleteOption option) => BillRead(
          type: 'bill',
          id: option.id,
          attributes: BillProperties(
            name: option.name,
            amountMin: '',
            amountMax: '',
            date: DateTime.now(),
            repeatFreq: BillRepeatFrequency.swaggerGeneratedUnknown,
          ),
        ),
        optionsBuilder: (String query) async {
          try {
            // Try to use BillRepository for local data
            final BillRepository? billRepository =
                context.read<BillRepository?>();

            if (billRepository != null) {
              final List<BillEntity> entities = await billRepository.getAll();
              // Filter by query text
              final String lowerQuery = query.toLowerCase();
              return entities
                  .where((BillEntity e) =>
                      e.name.toLowerCase().contains(lowerQuery))
                  .map((BillEntity e) => AutocompleteOption(
                        id: e.id,
                        name: e.name,
                      ))
                  .toList();
            }

            // Fallback to direct API call
            final FireflyIii api = context.read<FireflyService>().api;
            final Response<List<AutocompleteBill>> response =
                await api.v1AutocompleteBillsGet(query: query);
            apiThrowErrorIfEmpty(response, context.mounted ? context : null);

            return response.body!
                .map((AutocompleteBill e) => AutocompleteOption(
                      id: e.id,
                      name: e.name,
                    ))
                .toList();
          } catch (e, stackTrace) {
            log.severe(
              'Error while fetching bills',
              e,
              stackTrace,
            );
            return const <AutocompleteOption>[];
          }
        },
      ),
    ),
  );
}

/// Dialog widget for selecting a bill.
///
/// This widget is maintained for backwards compatibility but internally
/// uses [EntitySelectDialog] for the actual implementation.
///
/// Prefer using [showBillDialog] function for new code.
class BillDialog extends StatelessWidget {
  /// Creates a bill selection dialog.
  const BillDialog({super.key, required this.currentBill});

  /// The currently selected bill, if any.
  final BillRead? currentBill;

  @override
  Widget build(BuildContext context) {
    final Logger log = Logger('Pages.Transaction.Bill');

    return EntitySelectDialog<BillRead>(
      config: EntitySelectConfig<BillRead>(
        icon: Icons.calendar_today,
        title: S.of(context).transactionDialogBillTitle,
        labelText: S.of(context).transactionDialogBillTitle,
        clearButtonText: S.of(context).transactionDialogBillNoBill,
        initialValue: currentBill,
        initialDisplayText: currentBill?.attributes.name,
        emptyResultFactory: () => BillRead(
          type: 'bill',
          id: '0',
          attributes: BillProperties(
            name: '',
            amountMin: '',
            amountMax: '',
            date: DateTime.now(),
            repeatFreq: BillRepeatFrequency.swaggerGeneratedUnknown,
          ),
        ),
        resultFactory: (AutocompleteOption option) => BillRead(
          type: 'bill',
          id: option.id,
          attributes: BillProperties(
            name: option.name,
            amountMin: '',
            amountMax: '',
            date: DateTime.now(),
            repeatFreq: BillRepeatFrequency.swaggerGeneratedUnknown,
          ),
        ),
        optionsBuilder: (String query) async {
          try {
            // Try to use BillRepository for local data
            final BillRepository? billRepository =
                context.read<BillRepository?>();

            if (billRepository != null) {
              final List<BillEntity> entities = await billRepository.getAll();
              // Filter by query text
              final String lowerQuery = query.toLowerCase();
              return entities
                  .where((BillEntity e) =>
                      e.name.toLowerCase().contains(lowerQuery))
                  .map((BillEntity e) => AutocompleteOption(
                        id: e.id,
                        name: e.name,
                      ))
                  .toList();
            }

            // Fallback to direct API call
            final FireflyIii api = context.read<FireflyService>().api;
            final Response<List<AutocompleteBill>> response =
                await api.v1AutocompleteBillsGet(query: query);
            apiThrowErrorIfEmpty(response, context.mounted ? context : null);

            return response.body!
                .map((AutocompleteBill e) => AutocompleteOption(
                      id: e.id,
                      name: e.name,
                    ))
                .toList();
          } catch (e, stackTrace) {
            log.severe(
              'Error while fetching bills',
              e,
              stackTrace,
            );
            return const <AutocompleteOption>[];
          }
        },
      ),
    );
  }
}
