import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'item_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> items = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      final data = await supabase
          .from('items')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        items = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    }
  }

  IconData getItemIcon(String category) {
    String value = category.toLowerCase();

    if (value.contains('book')) {
      return Icons.menu_book;
    } else if (value.contains('phone') ||
        value.contains('electronic') ||
        value.contains('laptop')) {
      return Icons.devices;
    } else if (value.contains('card') ||
        value.contains('id')) {
      return Icons.badge;
    } else if (value.contains('key')) {
      return Icons.key;
    } else if (value.contains('bag') ||
        value.contains('wallet')) {
      return Icons.backpack;
    } else if (value.contains('cloth') ||
        value.contains('shirt')) {
      return Icons.checkroom;
    } else {
      return Icons.inventory_2;
    }
  }

  Future<void> openItemForm([Map<String, dynamic>? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemFormPage(item: item),
      ),
    );

    if (result == true) {
      loadItems();
    }
  }

  Future<void> deleteItem(Map<String, dynamic> item) async {
    try {
      await supabase
          .from('items')
          .delete()
          .eq('id', item['id']);

      loadItems();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item deleted successfully")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $error")),
      );
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    final userName = supabase.auth.currentUser
            ?.userMetadata?['full_name'] ??
        "Student";

    return Scaffold(
      appBar: AppBar(
        title: Text("Lost & Found"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 15),
                      Text("No items reported yet."),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    final isOwner =
                        item['user_id'] == userId;

                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  getItemIcon(item['category']),
                                  size: 40,
                                  color: Colors.blueGrey,
                                ),

                                SizedBox(width: 15),

                                Expanded(
                                  child: Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            Text(
                              "Type: ${item['item_type']}",
                            ),

                            Text(
                              "Category: ${item['category']}",
                            ),

                            Text(
                              "Location: ${item['location']}",
                            ),

                            SizedBox(height: 5),

                            Text(
                              "Description: ${item['description']}",
                            ),

                            if (isOwner)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      openItemForm(item);
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      deleteItem(item);
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openItemForm();
        },
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}