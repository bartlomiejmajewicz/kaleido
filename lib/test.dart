import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DropdownMenuExample(),
    );
  }
}

class DropdownMenuExample extends StatefulWidget {
  @override
  _DropdownMenuExampleState createState() => _DropdownMenuExampleState();
}

class _DropdownMenuExampleState extends State<DropdownMenuExample> {
  // Lista Stringów
  List<String> stringList = List.empty(growable: true);

  // Tworzenie listy DropdownMenuEntry na podstawie stringList
  List<DropdownMenuEntry<String>> getDropdownMenuEntries() {
    return stringList.map((String item) {
      return DropdownMenuEntry<String>(
        value: item,
        label: "Text($item)",
      );
    }).toList();
  }

  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DropdownMenu Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownMenu<String>(
              dropdownMenuEntries: getDropdownMenuEntries(),
              onSelected: (value) {
                setState(() {
                  selectedValue = value;
                });
              },
              initialSelection: selectedValue,
            ),
            SizedBox(height: 20),
            Text('Selected Value: $selectedValue'),
            ElevatedButton(onPressed: onPressed, child: Text("ADD OPT")),
          ],
        ),
      ),
    );
  }

  void onPressed() {
    setState(() {
      stringList.add("hej mała");
    });
  }
}
