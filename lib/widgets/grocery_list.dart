import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<GroceryItem> _groceryList = [];
  var _isLoading = true;
  String? _error ;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
     
    final url = Uri.https(
        'prep-e54dd-default-rtdb.firebaseio.com', 'shopping_list.json');
        try{final  response = await http.get(url);
        print(response.body);
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body) as Map<String, dynamic>;
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((element) => element.value.name == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          category: category,
          name: item.value['name'],
          quantity: int.parse(item.value['quantity'].toString())));
    }

    setState(() {
      _groceryList = loadedItems;
      _isLoading = false;
    });
  }
  catch(error){
    setState(() {
       _error = 'something went wrong';
    });
  print(error);
  }
  }

  void addItem() async {
    final newItem = await Navigator.of(context)
        .push<GroceryItem>(MaterialPageRoute(builder: (context) {
      return const NewItem();
    }));

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryList.add(newItem);
    });
  }

  void _removeItem(item) async {
    final index = _groceryList.indexOf(item);

    setState(() {
      _groceryList.remove(item);
    });

    final url = Uri.https('prep-e54dd-default-rtdb.firebaseio.com',
        'shopping_list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryList.insert(index, item);
      });}
    
    }


  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('Nothing here! Try adding some items.',
          style: TextStyle(
            fontSize: 20,
          )),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryList.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryList.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(_groceryList[index].id),
            onDismissed: (direction) {
              _removeItem(_groceryList[index]);
            },
            background: Container(
              height: 20,
              width: 20,
              color: const Color.fromARGB(190, 250, 4, 41),
            ),
            child: ListTile(
              title: Text(_groceryList[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryList[index].category.color,
              ),
              trailing: Text(_groceryList[index].quantity.toString()),
            ),
          );
        },
      );
    }

    if(_error != null){
      content = Center(child: Text(_error!),);
    }
  

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton.filled(
                onPressed: addItem,
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onSecondary,
                ))
          ],
        ),
        body: content);
  }

}