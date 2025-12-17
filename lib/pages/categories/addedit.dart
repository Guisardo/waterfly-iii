import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/settings.dart';

final Logger log = Logger("Pages.Categories.AddEdit");

class CategoryAddEditDialog extends StatefulWidget {
  const CategoryAddEditDialog({super.key, this.category});

  final CategoryRead? category;

  @override
  State<CategoryAddEditDialog> createState() => _CategoryAddEditDialogState();
}

class _CategoryAddEditDialogState extends State<CategoryAddEditDialog> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool loaded = false;
  bool includeInSum = true;

  @override
  void initState() {
    super.initState();

    if (widget.category == null) {
      // no setstate needed, the only if below checks for category null as well
      loaded = true;
      return;
    }

    titleController.text = widget.category!.attributes.name;

    // Use CategoryRepository instead of direct API call
    final CategoryRepository? categoryRepo = context.read<CategoryRepository?>();
    if (categoryRepo != null) {
      categoryRepo.getById(widget.category!.id).then((CategoryEntity? category) {
        if (category == null) {
          log.severe("Error fetching category from repository");
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
        setState(() {
          includeInSum =
              !context
                  .read<SettingsProvider>()
                  .categoriesSumExcluded
                  .contains(widget.category!.id);
          notesController.text = category.notes ?? "";
          loaded = true;
        });
      }).catchError((Object error, StackTrace stackTrace) {
        log.severe("Error fetching category", error, stackTrace);
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      // Fallback: No repository available
      log.warning("CategoryRepository not available");
      setState(() {
        loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //final Logger log = Logger("Pages.Categories.AddEditDialog");
    final double inputWidth = MediaQuery.of(context).size.width - 128 - 24;

    return AlertDialog(
      icon: const Icon(Icons.assignment),
      title: Text(
        widget.category == null
            ? S.of(context).categoryTitleAdd
            : S.of(context).categoryTitleEdit,
      ),
      clipBehavior: Clip.hardEdge,
      actions: <Widget>[
        if (widget.category != null)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.errorContainer,
              ),
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
            onPressed: () async {
              // Read repository before async gap
              final CategoryRepository categoryRepo = context.read<CategoryRepository>();
              
              final bool? ok = await showDialog(
                context: context,
                builder:
                    (BuildContext context) => const DeletionConfirmDialog(),
              );
              if (!(ok ?? false)) {
                return;
              }

              // Use CategoryRepository instead of direct API call
              try {
                await categoryRepo.delete(widget.category!.id);
                
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (error, stackTrace) {
                log.severe("Error deleting category", error, stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).errorUnknown),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          onPressed: () async {
            final ScaffoldMessengerState msg = ScaffoldMessenger.of(context);

            try {
              final CategoryRepository categoryRepo = context.read<CategoryRepository>();
              final DateTime now = DateTime.now();

              if (widget.category == null) {
                // Create new category
                final CategoryEntity newCategory = CategoryEntity(
                  id: '', // Will be generated by repository
                  serverId: null,
                  name: titleController.text,
                  notes: notesController.text,
                  createdAt: now,
                  updatedAt: now,
                  isSynced: false,
                  syncStatus: 'pending',
                );
                await categoryRepo.create(newCategory);
              } else {
                // Update existing category
                final CategoryEntity? existing = await categoryRepo.getById(widget.category!.id);
                if (existing != null) {
                  final CategoryEntity updatedCategory = CategoryEntity(
                    id: existing.id,
                    serverId: existing.serverId,
                    name: titleController.text,
                    notes: notesController.text,
                    createdAt: existing.createdAt,
                    updatedAt: now,
                    serverUpdatedAt: existing.serverUpdatedAt,
                    isSynced: false,
                    syncStatus: 'pending',
                  );
                  await categoryRepo.update(widget.category!.id, updatedCategory);
                }
              }

              if (context.mounted) {
                if (widget.category != null) {
                  if (includeInSum) {
                    await context
                        .read<SettingsProvider>()
                        .categoryRemoveSumExcluded(widget.category!.id);
                  } else {
                    await context.read<SettingsProvider>().categoryAddSumExcluded(
                      widget.category!.id,
                    );
                  }
                }
              }
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (error, stackTrace) {
              log.severe("Error saving category", error, stackTrace);
              msg.showSnackBar(
                SnackBar(
                  content: Text(
                    context.mounted
                        ? S.of(context).errorUnknown
                        : "Unknown error",
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: inputWidth,
              child: TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                  labelText: S.of(context).categoryFormLabelName,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: inputWidth,
              child: TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.description),
                  border: const OutlineInputBorder(),
                  labelText: S.of(context).transactionFormLabelNotes,
                ),
                enabled: loaded == true || widget.category == null,
                minLines: 1,
                maxLines: 5,
              ),
            ),
            // Only show toggle (+ spacing) when in edit mode
            if (widget.category != null) const SizedBox(height: 12),
            if (widget.category != null)
              SizedBox(
                width: inputWidth,
                child: SwitchListTile(
                  title: Text(S.of(context).categoryFormLabelIncludeInSum),
                  value: includeInSum,
                  isThreeLine: false,
                  onChanged:
                      loaded != true
                          ? null
                          : (bool value) => setState(() {
                            includeInSum = value;
                          }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DeletionConfirmDialog extends StatelessWidget {
  const DeletionConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.delete),
      title: Text(S.of(context).categoryTitleDelete),
      clipBehavior: Clip.hardEdge,
      actions: <Widget>[
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
          child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
      content: Text(S.of(context).categoryDeleteConfirm),
    );
  }
}
