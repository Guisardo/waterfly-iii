import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/piggy_bank_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/widgets/autocompletetext.dart';

// :TODO: make versatile and combine with bill.dart

class PiggyDialog extends StatefulWidget {
  const PiggyDialog({super.key, required this.currentPiggy});

  final PiggyBankRead? currentPiggy;

  @override
  State<PiggyDialog> createState() => _PiggyDialogState();
}

class _PiggyDialogState extends State<PiggyDialog> {
  final Logger log = Logger("Pages.Transaction.Piggy");

  final TextEditingController _piggyTextController = TextEditingController();
  final FocusNode _piggyFocusNode = FocusNode();

  PiggyBankRead? _piggy;

  @override
  void initState() {
    super.initState();

    _piggy = widget.currentPiggy;
    _piggyTextController.text = _piggy?.attributes.name ?? "";
  }

  @override
  void dispose() {
    _piggyTextController.dispose();
    _piggyFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.savings_outlined),
      title: Text(S.of(context).transactionDialogPiggyTitle),
      clipBehavior: Clip.hardEdge,
      scrollable: false,
      actions: <Widget>[
        TextButton(
          child: Text(S.of(context).transactionDialogPiggyNoPiggy),
          onPressed: () {
            Navigator.of(context).pop(
              const PiggyBankRead(
                type: "piggybank",
                id: "0",
                attributes: PiggyBankProperties(name: ""),
                links: ObjectLink(),
              ),
            );
          },
        ),
        FilledButton(
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          onPressed: () {
            Navigator.of(context).pop(_piggy);
          },
        ),
      ],
      content: SizedBox(
        width: 500,
        child: AutoCompleteText<AutocompletePiggy>(
          labelText: "Piggy Bank Name",
          //labelIcon: Icons.calendar_today,
          textController: _piggyTextController,
          focusNode: _piggyFocusNode,
          errorIconOnly: true,
          displayStringForOption: (AutocompletePiggy option) => option.name,
          onSelected: (AutocompletePiggy option) {
            log.finer(() => "selected piggy ${option.id}");
            setState(() {
              _piggy = PiggyBankRead(
                type: "piggybank",
                id: option.id,
                attributes: PiggyBankProperties(name: option.name),
                links: const ObjectLink(),
              );
            });
          },
          optionsBuilder: (TextEditingValue textEditingValue) async {
            try {
              final Isar isar = await AppDatabase.instance;
              final PiggyBankRepository piggyRepo = PiggyBankRepository(isar);
              final List<PiggyBankRead> piggyBanks = await piggyRepo.search(textEditingValue.text);
              
              // Convert PiggyBankRead to AutocompletePiggy format
              return piggyBanks.map((piggy) {
                return AutocompletePiggy(
                  id: piggy.id,
                  name: piggy.attributes.name,
                  currencyId: piggy.attributes.currencyId,
                  currencyCode: piggy.attributes.currencyCode,
                  currencySymbol: piggy.attributes.currencySymbol,
                  currencyName: piggy.attributes.currencyName,
                  currencyDecimalPlaces: piggy.attributes.currencyDecimalPlaces,
                  objectGroupId: piggy.attributes.objectGroupId,
                  objectGroupTitle: piggy.attributes.objectGroupTitle,
                );
              }).toList();
            } catch (e, stackTrace) {
              log.severe(
                "Error while fetching autocomplete from repository",
                e,
                stackTrace,
              );
              return const Iterable<AutocompletePiggy>.empty();
            }
          },
        ),
      ),
    );
  }
}
