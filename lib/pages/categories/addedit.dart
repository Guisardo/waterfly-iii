import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
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

  Future<void> _loadCategory() async {
    if (widget.category == null) {
      setState(() {
        loaded = true;
      });
      return;
    }

    titleController.text = widget.category!.attributes.name;

    try {
      final Isar isar = await AppDatabase.instance;
      final CategoryRepository categoryRepo = CategoryRepository(isar);
      final CategoryRead? category = await categoryRepo.getById(widget.category!.id);
      
      if (category == null) {
        log.severe("Category not found in repository");
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          includeInSum =
              !context
                  .read<SettingsProvider>()
                  .categoriesSumExcluded
                  .contains(widget.category!.id);
          notesController.text = category.attributes.notes ?? "";
          loaded = true;
        });
      }
    } catch (e, stackTrace) {
      log.severe("Error fetching category from repository", e, stackTrace);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.category == null) {
      // no setstate needed, the only if below checks for category null as well
      loaded = true;
      return;
    }

    titleController.text = widget.category!.attributes.name;

    // Fetch category from repository
    _loadCategory();
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
              final bool? ok = await showDialog(
                context: context,
                builder:
                    (BuildContext context) => const DeletionConfirmDialog(),
              );
              if (!(ok ?? false)) {
                return;
              }

              try {
                final Isar isar = await AppDatabase.instance;
                final CategoryRepository categoryRepo = CategoryRepository(isar);
                await categoryRepo.delete(widget.category!.id);
              } catch (e, stackTrace) {
                log.severe("Error deleting category", e, stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).errorUnknown),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }

              if (context.mounted) {
                Navigator.of(context).pop(true);
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
              final Isar isar = await AppDatabase.instance;
              final CategoryRepository categoryRepo = CategoryRepository(isar);
              
              if (widget.category == null) {
                // Create new category
                // For now, we'll need to call the API to get the full CategoryRead
                // TODO: Consider creating a method that generates a temporary ID
                // For now, keeping API call for create to get server-generated ID
                final FireflyIii api = context.read<FireflyService>().api;
                final resp = await api.v1CategoriesPost(
                  body: CategoryStore(
                    name: titleController.text,
                    notes: notesController.text,
                  ),
                );
                
                if (!resp.isSuccessful || resp.body == null) {
                  late String error;
                  try {
                    final ValidationErrorResponse valError =
                        ValidationErrorResponse.fromJson(
                          json.decode(resp.error.toString()),
                        );
                    error =
                        valError.message ??
                        (context.mounted
                            ? S.of(context).errorUnknown
                            : "[nocontext] Unknown error.");
                  } catch (_) {
                    error =
                        context.mounted
                            ? S.of(context).errorUnknown
                            : "[nocontext] Unknown error.";
                  }

                  msg.showSnackBar(
                    SnackBar(
                      content: Text(error),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                // Store in repository after successful API call
                await categoryRepo.upsertFromSync(resp.body!.data);
              } else {
                // Update existing category
                final CategoryRead? existing = await categoryRepo.getById(widget.category!.id);
                if (existing == null) {
                  msg.showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).errorUnknown),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                // Create updated category
                final Map<String, dynamic> categoryJson = existing.toJson();
                categoryJson['attributes'] = (categoryJson['attributes'] as Map<String, dynamic>)
                  ..['name'] = titleController.text
                  ..['notes'] = notesController.text;
                final CategoryRead updatedCategory = CategoryRead.fromJson(categoryJson);
                
                // Update via repository (queues for sync)
                await categoryRepo.update(updatedCategory);
              }

              if (context.mounted && widget.category != null) {
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
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (e, stackTrace) {
              log.severe("Error saving category", e, stackTrace);
              msg.showSnackBar(
                SnackBar(
                  content: Text(S.of(context).errorUnknown),
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
