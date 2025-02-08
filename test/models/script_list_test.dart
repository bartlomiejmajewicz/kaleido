import 'package:flutter_test/flutter_test.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/script_list.dart';
import 'package:script_editor/models/timecode.dart';

void main() {
  group('ScriptList Tests', () {
    late ScriptList scriptList;
    late List<ScriptNode> mockNodes;

    setUp(() {
      mockNodes = [
        ScriptNode(Timecode.fromIntValues(1, 5, 0, 0, 25), "characterName1", "dial 1"),
        ScriptNode(Timecode.fromIntValues(1, 8, 22, 0, 25), "characterName2", "dial 2"),
        ScriptNode(Timecode.fromIntValues(1, 10, 15, 0, 25), "characterName3", "dial 3"),
        ScriptNode(Timecode.fromIntValues(2, 15, 2, 0, 25), "characterName1", "dial 4"),
        ScriptNode(Timecode.fromIntValues(3, 5, 0, 0, 25), "characterName2", "dial 5"),
      ];
      scriptList = ScriptList(mockNodes);
    });

    test('markCurrentLine marks the correct line and returns true if changed', () {
      final currentPlaybackPosition = Timecode("01:08:25:00");
      final videoStartTc = Timecode("00:00:00:00");
      final videoFramerate = 25.0;

      final result = scriptList.markCurrentLine(currentPlaybackPosition, videoStartTc, videoFramerate);

      expect(result, isTrue);
      expect(scriptList.getItemById(0).isThisCurrentTC, isFalse);
      expect(scriptList.getItemById(2).isThisCurrentTC, isFalse);
    });

    test('getCharactersList returns unique character names sorted alphabetically', () {
      final result = scriptList.getCharactersList();

      expect(result, equals(["characterName1", "characterName2", "characterName3"]));
    });

    test('getList returns all lines when characterName is null', () {
      final result = scriptList.getList();

      expect(result, equals(mockNodes));
    });

    test('getList returns lines filtered by character name', () {
      final result = scriptList.getList(characterName: "characterName1");

      expect(result, hasLength(2));
      expect(result.every((node) => node.charName == "characterName1"), isTrue);
    });

    test('replaceCharName replaces character names and returns count', () {
      final count = scriptList.replaceCharName("characterName1", "newCharacterName");

      expect(count, equals(2));
      expect(mockNodes.where((node) => node.charName == "newCharacterName").length, equals(2));
    });

    test('newEntry adds a new ScriptNode and returns its index', () {
      Timecode tcIn = Timecode("02:00:00:00");
      String charName = "newChar";
      String dial = "newDialogue";
      int newIndex = scriptList.newEntry(tcIn,
          charName: charName, dial: dial);

      expect(tcIn.framesCount(), scriptList.getList()[newIndex].tcIn.framesCount());
      expect(charName, scriptList.getList()[newIndex].charName);
      expect(dial, scriptList.getList()[newIndex].dialLoc);
    });

    test('removeItemById removes item at given id', () {
      final initialLength = mockNodes.length;
      scriptList.removeItemById(0);

      expect(mockNodes.length, equals(initialLength - 1));
    });

    test('removeItem removes the specific ScriptNode', () {
      final nodeToRemove = mockNodes[0];
      scriptList.removeItem(nodeToRemove);

      expect(mockNodes.contains(nodeToRemove), isFalse);
    });

    test('getItemById returns the correct item', () {
      final item = scriptList.getItemById(0);

      expect(item, equals(mockNodes[0]));
    });

    test('sortItems sorts the list', () {
      scriptList.sortItems();

      expect(mockNodes, orderedEquals(mockNodes..sort()));
    });
  });
}
