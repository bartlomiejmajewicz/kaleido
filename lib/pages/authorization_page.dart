import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/bloc/auth_bloc.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/unique_device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Authorisation.initialize();
  runApp(MaterialApp(home: AuthorizationPage()));
}

class LicenseNotifier extends ChangeNotifier {
  void reload() {
    notifyListeners();
  }
}

class AuthorizationPage extends StatelessWidget {
  AuthorizationPage({super.key});

  final TextEditingController _tecEmail = TextEditingController();
  final TextEditingController _tecCode = TextEditingController();
  final TextEditingController _tecLicenseEnc = TextEditingController();
  final TextEditingController _tecIv = TextEditingController();
  final ValueNotifier<bool> _showSecretButton = ValueNotifier(false);
  final ValueNotifier<bool> _showOfflineAuthorizationFields = ValueNotifier(false);
  final double _textFieldWidth = 400;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: ChangeNotifierProvider(
        create: (context) => LicenseNotifier(),
        child: Scaffold(
          body: Center(
            child: ListView(padding: const EdgeInsets.all(18.0), children: [
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.messageToDisplay != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.messageToDisplay!)));
                  }
                },
                builder: (context, state) {
                  return Center(
                    child: Text(state.licenseStatusText,
                        style: const TextStyle(fontSize: 20)),
                  ); 
                },
              ),

              FutureBuilder(
                future: UniqueDeviceId.getDeviceUuid(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: SelectableText(
                        "Your device ID is: ${snapshot.data}",
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  } else {
                    return const CircularProgressIndicator.adaptive();
                  }
                  
                },
              ),


              Column(
                children: [
                  SizedBox(
                    width: _textFieldWidth,
                    child: TextField(
                      decoration: const InputDecoration(helperText: "email"),
                      controller: _tecEmail,
                    ),
                  ),
                  SizedBox(
                    width: _textFieldWidth,
                    child: TextField(
                      decoration: const InputDecoration(helperText: "license code"),
                      controller: _tecCode,
                    ),
                  ),
                ],
              ),


              ValueListenableBuilder(
                    valueListenable: _showOfflineAuthorizationFields,
                    builder: (context, value, child) {
                      if (value == false) {
                        return Container();
                      }
                      return Column(
                        children: [
                          SizedBox(
                            width: _textFieldWidth,
                            child: TextField(
                              decoration: const InputDecoration(helperText: "license string A"),
                              controller: _tecLicenseEnc,
                            ),
                          ),
                          SizedBox(
                            width: _textFieldWidth,
                            child: TextField(
                              decoration: const InputDecoration(helperText: "license string B"),
                              controller: _tecIv,
                            ),
                          ),
                        ],
                      );
                    },),



              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Column(
                    key: UniqueKey(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: OutlinedButton(
                          key: UniqueKey(),
                            onPressed: state is AuthLicenseActive || state is AuthLoadingLicense
                              ? null
                              : () {
                                if (_showOfflineAuthorizationFields.value) {
                                  context.read<AuthBloc>().add(AuthActivateLicenseOffline(_tecEmail.text, _tecCode.text, _tecLicenseEnc.text, _tecIv.text));
                                } else {
                                  context.read<AuthBloc>().add(AuthActivateLicense(_tecEmail.text, _tecCode.text));
                                }

                              },
                            child: const Text("Activate License")),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: OutlinedButton(
                          key: UniqueKey(),
                            onPressed: state is AuthLicenseActive
                                ? () {
                                    context.read<AuthBloc>().add(AuthDeactivateLicense());
                                  }
                                : null,
                            child: const Text("Deactivate License")),
                      ),
                      Container(
                        child: state is AuthLoadingLicense ? const CircularProgressIndicator.adaptive() : null,
                      )
                    ],
                  );
                },
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: OutlinedButton(
                        onLongPress: () => _showSecretButton.value = !_showSecretButton.value,
                        onPressed: () => _showLicenseInfo(
                            Authorisation.extractLicenseDetails(), context),
                        child: const Text("Show license info")),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _showSecretButton,
                    builder: (context, value, child) {
                      if (value == false) {
                        return Container();
                      }
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: OutlinedButton(
                            onPressed: () async {
                              SharedPreferences sp =
                                  await SharedPreferences.getInstance();
                              sp.clear();
                              context.read<AuthBloc>().add(AuthForceInitialState());
                            },
                            child: const Text(
                                "Remove all license data (do not use unless instructed)")),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: OutlinedButton(
                      onPressed: (){
                        _showOfflineAuthorizationFields.value = !_showOfflineAuthorizationFields.value;
                      },
                      child: const Text("Offline authorization")),
                  ),

                  
                  
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showLicenseInfo(
      LicenseDetails? license, BuildContext context) async {
    if (license == null) {
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
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