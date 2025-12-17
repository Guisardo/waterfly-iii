import 'package:chopper/chopper.dart' show Response;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/piggy_bank_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/widgets/entity_select_dialog.dart';

/// Shows a dialog to select a piggy bank.
///
/// This is a convenience function that uses [EntitySelectDialog] configured
/// for piggy bank selection. It returns the selected [PiggyBankRead] or null
/// if cancelled.
///
/// Example:
/// ```dart
/// final piggy = await showPiggyBankDialog(
///   context: context,
///   currentPiggy: existingPiggy,
/// );
/// ```
Future<PiggyBankRead?> showPiggyBankDialog({
  required BuildContext context,
  PiggyBankRead? currentPiggy,
}) {
  // ignore: unused_local_variable
  final Logger log = Logger('PiggyDialog');

  return showDialog<PiggyBankRead>(
    context: context,
    builder: (BuildContext dialogContext) => EntitySelectDialog<PiggyBankRead>(
      config: EntitySelectConfig<PiggyBankRead>(
        icon: Icons.savings_outlined,
        title: S.of(context).transactionDialogPiggyTitle,
        labelText: S.of(context).transactionDialogPiggyTitle,
        clearButtonText: S.of(context).transactionDialogPiggyNoPiggy,
        initialValue: currentPiggy,
        initialDisplayText: currentPiggy?.attributes.name,
        emptyResultFactory: () => const PiggyBankRead(
          type: 'piggybank',
          id: '0',
          attributes: PiggyBankProperties(name: ''),
          links: ObjectLink(),
        ),
        resultFactory: (AutocompleteOption option) => PiggyBankRead(
          type: 'piggybank',
          id: option.id,
          attributes: PiggyBankProperties(name: option.name),
          links: const ObjectLink(),
        ),
        optionsBuilder: (String query) async {
          try {
            // Try to use PiggyBankRepository for local data
            final PiggyBankRepository? piggyRepository =
                context.read<PiggyBankRepository?>();

            if (piggyRepository != null) {
              final List<PiggyBankEntity> entities =
                  await piggyRepository.getAll();
              // Filter by query text
              final String lowerQuery = query.toLowerCase();
              return entities
                  .where((PiggyBankEntity e) =>
                      e.name.toLowerCase().contains(lowerQuery))
                  .map((PiggyBankEntity e) => AutocompleteOption(
                        id: e.id,
                        name: e.name,
                      ))
                  .toList();
            }

            // Fallback to direct API call
            final FireflyIii api = context.read<FireflyService>().api;
            final Response<List<AutocompletePiggy>> response =
                await api.v1AutocompletePiggyBanksGet(query: query);
            apiThrowErrorIfEmpty(response, context.mounted ? context : null);

            return response.body!
                .map((AutocompletePiggy e) => AutocompleteOption(
                      id: e.id,
                      name: e.name,
                    ))
                .toList();
          } catch (e, stackTrace) {
            log.severe(
              'Error while fetching piggy banks',
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

/// Dialog widget for selecting a piggy bank.
///
/// This widget is maintained for backwards compatibility but internally
/// uses [EntitySelectDialog] for the actual implementation.
///
/// Prefer using [showPiggyBankDialog] function for new code.
class PiggyDialog extends StatelessWidget {
  /// Creates a piggy bank selection dialog.
  const PiggyDialog({super.key, required this.currentPiggy});

  /// The currently selected piggy bank, if any.
  final PiggyBankRead? currentPiggy;

  @override
  Widget build(BuildContext context) {
    final Logger log = Logger('Pages.Transaction.Piggy');

    return EntitySelectDialog<PiggyBankRead>(
      config: EntitySelectConfig<PiggyBankRead>(
        icon: Icons.savings_outlined,
        title: S.of(context).transactionDialogPiggyTitle,
        labelText: S.of(context).transactionDialogPiggyTitle,
        clearButtonText: S.of(context).transactionDialogPiggyNoPiggy,
        initialValue: currentPiggy,
        initialDisplayText: currentPiggy?.attributes.name,
        emptyResultFactory: () => const PiggyBankRead(
          type: 'piggybank',
          id: '0',
          attributes: PiggyBankProperties(name: ''),
          links: ObjectLink(),
        ),
        resultFactory: (AutocompleteOption option) => PiggyBankRead(
          type: 'piggybank',
          id: option.id,
          attributes: PiggyBankProperties(name: option.name),
          links: const ObjectLink(),
        ),
        optionsBuilder: (String query) async {
          try {
            // Try to use PiggyBankRepository for local data
            final PiggyBankRepository? piggyRepository =
                context.read<PiggyBankRepository?>();

            if (piggyRepository != null) {
              final List<PiggyBankEntity> entities =
                  await piggyRepository.getAll();
              // Filter by query text
              final String lowerQuery = query.toLowerCase();
              return entities
                  .where((PiggyBankEntity e) =>
                      e.name.toLowerCase().contains(lowerQuery))
                  .map((PiggyBankEntity e) => AutocompleteOption(
                        id: e.id,
                        name: e.name,
                      ))
                  .toList();
            }

            // Fallback to direct API call
            final FireflyIii api = context.read<FireflyService>().api;
            final Response<List<AutocompletePiggy>> response =
                await api.v1AutocompletePiggyBanksGet(query: query);
            apiThrowErrorIfEmpty(response, context.mounted ? context : null);

            return response.body!
                .map((AutocompletePiggy e) => AutocompleteOption(
                      id: e.id,
                      name: e.name,
                    ))
                .toList();
          } catch (e, stackTrace) {
            log.severe(
              'Error while fetching piggy banks',
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
