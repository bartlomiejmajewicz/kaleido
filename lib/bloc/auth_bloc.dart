import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:script_editor/models/authorisation.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {

  static AuthState _initialStateSelector(){
    if (Authorisation.isLicensePresent()) {
      return AuthLicenseActive(null);
    }
    return AuthLicenseNotActive(null);
  }

  AuthBloc() : super(_initialStateSelector()) {
    // if (Authorisation.isLicensePresent()) {
    //   emit(AuthLicenseActive(null));
    // }
    on<AuthDeactivateLicense>(_deAuthoriseLicense);
    on<AuthActivateLicense>(_authoriseLicense);
    on<AuthActivateLicenseOffline>(_authoriseOffline);
    on<AuthForceInitialState>(_forceInitialState);
  }

  void _forceInitialState(AuthForceInitialState event, Emitter<AuthState> emit){
    Authorisation.clearAllLicenseData();
    emit(AuthLicenseNotActive(null));
  }

  Future<void> _authoriseLicense(AuthActivateLicense event, Emitter<AuthState> emit) async {
    emit(AuthLoadingLicense());
    final String email = event.email;
    final String licenseCode = event.licenseCode;

    final Authorisation authorisation = Authorisation();

    final String response = await authorisation.pullLicenseFromServer(email, licenseCode, null);

    if (Authorisation.isLicensePresent()) {
      emit(AuthLicenseActive(response));
    } else {
      emit(AuthLicenseNotActive(response));
    }
  }


  Future<void> _authoriseOffline(AuthActivateLicenseOffline event, Emitter<AuthState> emit) async {
    emit(AuthLoadingLicense());
    final String email = event.email;
    final String licenseCode = event.licenseCode;
    final String licenseStringEncoded = event.licenseStringEncoded;
    final String licenseStringIv = event.licenseStringIv;

    final int responseCode = await Authorisation.authoriseLocally(email, licenseCode, licenseStringEncoded, licenseStringIv);
    String responseString = "License activated properly";
    switch (responseCode) {
      case 1:
        responseString = "License data incorrect";
        break;
      case 2:
        responseString = "Missing license data";
        break;
    }

    if (Authorisation.isLicensePresent()) {
      emit(AuthLicenseActive(responseString));
    } else {
      emit(AuthLicenseNotActive(responseString));
    }
  }



  Future<void> _deAuthoriseLicense(AuthEvent event, Emitter<AuthState> emit) async {

    emit(AuthLoadingLicense());

    final Authorisation authorisation = Authorisation();
    final String response = await authorisation.pushLicenseToServer();
    if (Authorisation.isLicensePresent()) {
      emit(AuthLicenseActive(response));
    } else {
      emit(AuthLicenseNotActive(response));
    }
  }


}
