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
    on<AuthForceInitialState>(_forceInitialState);
  }

  void _forceInitialState(AuthForceInitialState event, Emitter<AuthState> emit){
    Authorisation.clearAllLicenseData();
    emit(AuthInitial());
  }

  Future<void> _authoriseLicense(AuthActivateLicense event, Emitter<AuthState> emit) async {
    emit(AuthLoadingLicense());
    final String email = event.email;
    final String licenseCode = event.licenseCode;

    final Authorisation authorisation = Authorisation();

    final String response = await authorisation.pullLicenseFromServer(email, licenseCode, null);
    print(response);

    if (Authorisation.isLicensePresent()) {
      emit(AuthLicenseActive(response));
    } else {
      emit(AuthLicenseNotActive(response));
    }
  }

  Future<void> _deAuthoriseLicense(AuthEvent event, Emitter<AuthState> emit) async {

    emit(AuthLoadingLicense());

    final Authorisation authorisation = Authorisation();
    final String response = await authorisation.pushLicenseToServer();
    print(response);
    if (Authorisation.isLicensePresent()) {
      emit(AuthLicenseActive(response));
    } else {
      emit(AuthLicenseNotActive(response));
    }
  }


}
