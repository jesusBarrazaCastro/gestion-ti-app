import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'button.dart';

class SimpleTable extends StatefulWidget {
  // 1. Pass the list in the constructor and make it final.
  final List<dynamic> dataList;

  // Optional: You could also pass a callback (e.g., VoidCallback onDataChanged)
  // to notify the parent when the data is changed if needed for more complex state management.

  const SimpleTable({
    super.key,
    required this.dataList,
  });

  @override
  State<SimpleTable> createState() => _SimpleTableState();
}

class _SimpleTableState extends State<SimpleTable> {
  // 2. Internal state variables for editing logic
  bool isEditing = false;
  int? editingIndex;
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  // 3. Helper to toggle editing mode and update the UI
  void _toggleEdit(int? index) {
    setState(() {
      isEditing = index != null;
      editingIndex = index;
      if (index != null) {
        // Load data into controllers when starting to edit
        nombreController.text = widget.dataList[index]['nombre'] ?? '';
        descripcionController.text = widget.dataList[index]['descripcion'] ?? '';
      } else {
        // Clear controllers when done editing/canceled
        nombreController.clear();
        descripcionController.clear();
      }
    });
  }

  // 4. Implement CRUD operations that modify widget.dataList
  void _saveEdit() {
    if (editingIndex != null && editingIndex! < widget.dataList.length) {
      // Modifies the original list passed from the parent
      widget.dataList[editingIndex!] = {
        'nombre': nombreController.text,
        'descripcion': descripcionController.text,
      };
      // Reset state variables and rebuild
      _toggleEdit(null);
      // NOTE: The parent widget's state won't automatically rebuild unless
      // it is listening for a change or the table forces an external update (e.g., via a callback).
      // However, the list reference is shared, so the underlying data is updated.
    }
  }

  void _addItem() {
    // Add new item logic (simplified)
    if (nombreController.text.isNotEmpty && descripcionController.text.isNotEmpty) {
      setState(() {
        widget.dataList.add({
          'nombre': nombreController.text,
          'descripcion': descripcionController.text,
        });
        nombreController.clear();
        descripcionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: 600,
      decoration: BoxDecoration(
          color: AppTheme.light.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18)
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // --- Header Row for Labels and Add Button ---
          Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('Nombre', style: AppTheme.light.bodyBold,)
              ),
              const SizedBox(width: 10,),
              Expanded(
                  flex: 2,
                  child: Text('Descripcion', style: AppTheme.light.bodyBold,)
              ),
              const Spacer(),
              Button(
                width: 130,
                text: 'Agregar',
                icon: Icons.add_box_outlined,
                onPressed: _addItem, // Use the addItem function
              )
            ],
          ),
          // --- Input Fields for Add/Edit ---
          if (!isEditing) // Show input fields for adding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nuevo Nombre'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Nueva Descripción'),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 130), // Alignment spacer
                ],
              ),
            ),
          const SizedBox(height: 5,),
          const Divider(),
          const SizedBox(height: 5,),
          // --- List View for Data Rows ---
          Expanded( // Use Expanded to give ListView.builder a bounded height
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.dataList.length,
              itemBuilder:  (context, index) {
                dynamic item = widget.dataList[index];
                final bool isCurrentEditing = isEditing && editingIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Name Field
                      Expanded(
                        flex: 1,
                        child: isCurrentEditing
                            ? TextField(
                          controller: nombreController,
                          decoration: const InputDecoration.collapsed(hintText: 'Nombre'),
                        )
                            : Text(item['nombre'] ?? '', style: AppTheme.light.body),
                      ),
                      const SizedBox(width: 10,),
                      // Description Field
                      Expanded(
                        flex: 2,
                        child: isCurrentEditing
                            ? TextField(
                          controller: descripcionController,
                          decoration: const InputDecoration.collapsed(hintText: 'Descripción'),
                        )
                            : Text(item['descripcion'] ?? '', style: AppTheme.light.body),
                      ),
                      const Spacer(),
                      // Action Buttons
                      SizedBox(
                        width: 130,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if(!isEditing) // Only show edit when nothing else is being edited
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black,),
                                onPressed: () => _toggleEdit(index),
                              ),
                            if(isCurrentEditing)...[ // Show save/cancel when editing this row
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green,),
                                onPressed: _saveEdit, // Save the changes
                              ),
                              const SizedBox(width: 5,),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.black,),
                                onPressed: () => _toggleEdit(null), // Cancel editing
                              ),
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}