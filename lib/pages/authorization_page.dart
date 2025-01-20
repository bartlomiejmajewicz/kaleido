
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/unique_device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';


// void main(List<String> args) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Authorisation.initialize();
//   runApp(
//     const MaterialApp(
//       home: AuthorizationPage())
//   );
// }

class LicenseNotifier extends ChangeNotifier{
  void reload(){
    notifyListeners();
  }
}

class AuthorizationPage extends StatefulWidget{
  const AuthorizationPage({super.key});

  @override
  State<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends State<AuthorizationPage> {
  final Authorisation _auth = Authorisation();
  final TextEditingController _tecEmail = TextEditingController();
  final TextEditingController _tecCode = TextEditingController();
  final LicenseNotifier _licenseNotifier = LicenseNotifier();
  final ValueNotifier<bool> _showSecretButton = ValueNotifier(false);
  final double _textFieldWidth = 200;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LicenseNotifier(),
      child: Scaffold(
        body: Center(
          child: ListView(
            padding: const EdgeInsets.all(18.0),
            children: [
            ListenableBuilder(
              listenable: _licenseNotifier,
              builder: (context, child) {
                return Center(
                  child: Text(
                    Authorisation.licenseStatusText(),
                    style: const TextStyle(fontSize: 20)),
                );
                },
            ),
            FutureBuilder(
              future: UniqueDeviceId.getDeviceUuid(),
              builder: (context, snapshot) {
                return Center(
                  child: SelectableText(
                    "Your device ID is: ${snapshot.data}",
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              },
            ),
            
            SizedBox(
              width: _textFieldWidth,
              child: TextField(
                decoration: const InputDecoration(
                  helperText: "email"
                  ),
                controller: _tecEmail,
              ),
            ),
            
            SizedBox(
              width: _textFieldWidth,
              child: TextField(
                decoration: const InputDecoration(
                  helperText: "license code"
                  ),
                controller: _tecCode,
              ),
            ),
            ListenableBuilder(
              listenable: _licenseNotifier,
              builder: (context, child) {
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: OutlinedButton(
                      onPressed: Authorisation.isLicensePresent() ? null : () async {
                          String response = await _auth.pullLicenseFromServer(_tecEmail.text, _tecCode.text, null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response)));
                          _licenseNotifier.reload();
                        },
                      child: const Text("Activate License")),
                  ),
                
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: OutlinedButton(
                      onPressed: Authorisation.isLicensePresent() ? () async {
                        String response = await _auth.pushLicenseToServer();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response)));
                          _licenseNotifier.reload();
                      } : null,
                      child: Text("Deactivate License")),
                  ),
                ],);
                          
              },
              
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: OutlinedButton(
                    onLongPress: () => _showSecretButton.value = true,
                    onPressed: ()=> _showLicenseInfo(Authorisation.extractLicenseDetails(), context),
                    child: const Text("Show license info")),
                ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: ValueListenableBuilder(
                  valueListenable: _showSecretButton,
                  builder: (context, value, child) {
                    if (value == false) {
                      return Container();
                    }
                    return OutlinedButton(
                      onPressed: () async {
                        SharedPreferences sp = await SharedPreferences.getInstance();
                        sp.clear();
                        _licenseNotifier.reload();
                      },
                      child: const Text("Remove all license data (do not use unless instructed)"));
                },
                ),
              )
              ],
            ),
            ]
          ),
        ),
      ),
    );
  }


  Future<void> _showLicenseInfo(LicenseDetails? license, BuildContext context) async {
    if (license == null) {
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('License info:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SelectableText("License id: ${license.licenseId}"),
                SelectableText("License email: ${license.email}"),
                SelectableText("License start: ${license.licenseStart}"),
                SelectableText("License expire: ${license.licenseEnd}"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}