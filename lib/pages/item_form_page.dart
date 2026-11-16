import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/input_field.dart';

class ItemFormPage extends StatefulWidget {
  final Map<String, dynamic>? item;

  const ItemFormPage({
    super.key,
    this.item,
  });

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final supabase = Supabase.instance.client;

  TextEditingController titleController =
      TextEditingController();

  TextEditingController categoryController =
      TextEditingController();

  TextEditingController typeController =
      TextEditingController();

  TextEditingController locationController =
      TextEditingController();

  TextEditingController descriptionController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.item != null) {
      titleController.text = widget.item!['title'];
      categoryController.text = widget.item!['category'];
      typeController.text = widget.item!['item_type'];
      locationController.text = widget.item!['location'];
      descriptionController.text = widget.item!['description'];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    typeController.dispose();
    locationController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  Future<void> saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final user = supabase.auth.currentUser;

        if (user == null) {
          throw Exception("Please login first");
        }

        final itemData = {
          'title': titleController.text.trim(),
          'category': categoryController.text.trim(),
          'item_type':
              typeController.text.trim().toLowerCase() == 'lost'
                  ? 'Lost'
                  : 'Found',
          'location': locationController.text.trim(),
          'description': descriptionController.text.trim(),
        };

        if (widget.item == null) {
          // CREATE operation

          await supabase.from('items').insert({
            'user_id': user.id,
            ...itemData,
          });
        } else {
          // UPDATE operation

          await supabase
              .from('items')
              .update(itemData)
              .eq('id', widget.item!['id']);
        }

        if (!mounted) return;

        Navigator.pop(context, true);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Operation failed: $error"),
            ),
          );

          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? "Report an Item"
              : "Edit Item",
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                InputField(
                  controller: titleController,
                  keyboardType: TextInputType.text,
                  labelText: "Item Name",
                  hintText: "Enter item name",
                  prefixIcon: Icon(Icons.inventory_2),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Item name is required";
                    } else if (!RegExp(
                      r"^[A-Za-z0-9][A-Za-z0-9 &().,'-]{1,79}$",
                    ).hasMatch(value.trim())) {
                      return "Enter a valid item name";
                    }

                    return null;
                  },
                ),

                SizedBox(height: 20),

                InputField(
                  controller: categoryController,
                  keyboardType: TextInputType.text,
                  labelText: "Category",
                  hintText: "Books, Electronics, ID Card, etc.",
                  prefixIcon: Icon(Icons.category),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Category is required";
                    } else if (!RegExp(
                      r"^[A-Za-z][A-Za-z0-9 &'-]{1,39}$",
                    ).hasMatch(value.trim())) {
                      return "Enter a valid category";
                    }

                    return null;
                  },
                ),

                SizedBox(height: 20),

                InputField(
                  controller: typeController,
                  keyboardType: TextInputType.text,
                  labelText: "Item Type",
                  hintText: "Enter Lost or Found",
                  prefixIcon: Icon(Icons.swap_horiz),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(
                          r'^(Lost|Found)$',
                          caseSensitive: false,
                        ).hasMatch(value.trim())) {
                      return "Enter Lost or Found";
                    }

                    return null;
                  },
                ),

                SizedBox(height: 20),

                InputField(
                  controller: locationController,
                  keyboardType: TextInputType.text,
                  labelText: "Location",
                  hintText: "Where was it lost or found?",
                  prefixIcon: Icon(Icons.location_on),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Location is required";
                    } else if (!RegExp(
                      r"^[A-Za-z0-9 ,.'()/#-]{2,80}$",
                    ).hasMatch(value.trim())) {
                      return "Enter a valid location";
                    }

                    return null;
                  },
                ),

                SizedBox(height: 20),

                InputField(
                  controller: descriptionController,
                  keyboardType: TextInputType.multiline,
                  labelText: "Description",
                  hintText: "Describe the item",
                  prefixIcon: Icon(Icons.description),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Description is required";
                    } else if (!RegExp(
                      r'^.{10,500}$',
                      dotAll: true,
                    ).hasMatch(value.trim())) {
                      return "Description must be 10-500 characters";
                    }

                    return null;
                  },
                ),

                SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveItem,
                    child: Text(
                      isLoading
                          ? "Saving..."
                          : widget.item == null
                              ? "Submit Report"
                              : "Update Report",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}