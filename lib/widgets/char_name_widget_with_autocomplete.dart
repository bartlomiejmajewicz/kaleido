import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CharNameWidgetWithAutocomplete extends StatelessWidget {
  List<String> charactersNamesList;
  String initialValue;
  void Function(String value) updateFunction;
  CharNameWidgetWithAutocomplete({super.key, required this.charactersNamesList, required this.initialValue, required this.updateFunction});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return charactersNamesList.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        updateFunction(selection);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            updateFunction(value);
          },
          onFieldSubmitted: (value) {
            onFieldSubmitted();
          },
        );
      },
    );
  }
}



