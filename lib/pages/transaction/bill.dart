import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/bill_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart' as enums;
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/widgets/autocompletetext.dart';

class BillDialog extends StatefulWidget {
  const BillDialog({super.key, required this.currentBill});

  final BillRead? currentBill;

  @override
  State<BillDialog> createState() => _BillDialogState();
}

class _BillDialogState extends State<BillDialog> {
  final Logger log = Logger("Pages.Transaction.Bill");

  final TextEditingController _billTextController = TextEditingController();
  final FocusNode _billFocusNode = FocusNode();

  BillRead? _bill;

  @override
  void initState() {
    super.initState();

    _bill = widget.currentBill;
    _billTextController.text = _bill?.attributes.name ?? "";
  }

  @override
  void dispose() {
    _billTextController.dispose();
    _billFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.calendar_today),
      title: Text(S.of(context).transactionDialogBillTitle),
      clipBehavior: Clip.hardEdge,
      scrollable: false,
      actions: <Widget>[
        TextButton(
          child: Text(S.of(context).transactionDialogBillNoBill),
          onPressed: () {
            Navigator.of(context).pop(
              BillRead(
                type: "bill",
                id: "0",
                attributes: BillProperties(
                  name: "",
                  amountMin: "",
                  amountMax: "",
                  date: DateTime.now(),
                  repeatFreq: enums.BillRepeatFrequency.swaggerGeneratedUnknown,
                ),
              ),
            );
          },
        ),
        FilledButton(
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          onPressed: () {
            Navigator.of(context).pop(_bill);
          },
        ),
      ],
      content: SizedBox(
        width: 500,
        child: AutoCompleteText<AutocompleteBill>(
          labelText: "Bill Name",
          //labelIcon: Icons.calendar_today,
          textController: _billTextController,
          focusNode: _billFocusNode,
          errorIconOnly: true,
          displayStringForOption: (AutocompleteBill option) => option.name,
          onSelected: (AutocompleteBill option) {
            log.finer(() => "selected bill ${option.id}");
            setState(() {
              _bill = BillRead(
                type: "bill",
                id: option.id,
                attributes: BillProperties(
                  name: option.name,
                  amountMin: "",
                  amountMax: "",
                  date: DateTime.now(),
                  repeatFreq: enums.BillRepeatFrequency.swaggerGeneratedUnknown,
                ),
              );
            });
          },
          optionsBuilder: (TextEditingValue textEditingValue) async {
            try {
              final Isar isar = await AppDatabase.instance;
              final BillRepository billRepo = BillRepository(isar);
              final List<BillRead> bills = await billRepo.search(textEditingValue.text);
              
              // Convert BillRead to AutocompleteBill format
              return bills.map((bill) {
                return AutocompleteBill(
                  id: bill.id,
                  name: bill.attributes.name ?? "",
                  active: bill.attributes.active,
                );
              }).toList();
            } catch (e, stackTrace) {
              log.severe(
                "Error while fetching autocomplete from repository",
                e,
                stackTrace,
              );
              return const Iterable<AutocompleteBill>.empty();
            }
          },
        ),
      ),
    );
  }
}
