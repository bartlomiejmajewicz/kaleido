import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ignore: must_be_immutable
class CharNameWidgetWithAutocomplete extends StatelessWidget {
  List<String> charactersNamesList;
  String initialValue;
  void Function(String value) updateFunction;
  final double maxOptionsWidth;
  CharNameWidgetWithAutocomplete({
    super.key,
    required this.charactersNamesList,
    required this.initialValue,
    required this.updateFunction,
    required this.maxOptionsWidth});

  String stringForString(String opt){
    return opt;
  }

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


      optionsViewBuilder: (BuildContext context, onSelected, options) {
        return _AutocompleteOptions<String>(
          displayStringForOption: stringForString,
          onSelected: onSelected,
          options: options,
          openDirection: OptionsViewOpenDirection.down,
          maxOptionsHeight: 200,
          maxOptionsWidth: maxOptionsWidth,
        );
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






// COPIED FROM THE AUTOCOMPLETE CLASS TO PASS maxOptionsWidth VALUE
class _AutocompleteOptions<T extends Object> extends StatelessWidget {
  const _AutocompleteOptions({
    super.key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.openDirection,
    required this.options,
    required this.maxOptionsHeight,
    required this.maxOptionsWidth,
  });

  final AutocompleteOptionToString<T> displayStringForOption;

  final AutocompleteOnSelected<T> onSelected;
  final OptionsViewOpenDirection openDirection;

  final Iterable<T> options;
  final double maxOptionsHeight;
  final double maxOptionsWidth;

  @override
  Widget build(BuildContext context) {
    final AlignmentDirectional optionsAlignment = switch (openDirection) {
      OptionsViewOpenDirection.up => AlignmentDirectional.bottomStart,
      OptionsViewOpenDirection.down => AlignmentDirectional.topStart,
    };
    return Align(
      alignment: optionsAlignment,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxOptionsHeight,
            maxWidth: maxOptionsWidth),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final T option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(option);
                },
                child: Builder(
                  builder: (BuildContext context) {
                    final bool highlight = AutocompleteHighlightedOption.of(context) == index;
                    if (highlight) {
                      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                        /**
                         * FlutterError (Looking up a deactivated widget's ancestor is unsafe.
                            At this point the state of the widget's element tree is no longer stable.
                            To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.)
                         * 
                         */
                        try{
                        Scrollable.ensureVisible(context, alignment: 0.5);
                        // ignore: empty_catches
                        } catch (e){
                        }
                      }, debugLabel: 'AutocompleteOptions.ensureVisible');
                    }
                    return Container(
                      color: highlight ? Theme.of(context).focusColor : null,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(displayStringForOption(option)),
                    );
                  }
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}