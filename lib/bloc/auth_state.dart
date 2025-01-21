part of 'auth_bloc.dart';

@immutable
// ignore: must_be_immutable
sealed class AuthState {
  late String licenseStatusText = "";
  String? messageToDisplay;
  AuthState(){
    licenseStatusText = Authorisation.licenseStatusText();
  }
}

// ignore: must_be_immutable
final class AuthInitial extends AuthState {
  AuthInitial():super();
}

// ignore: must_be_immutable
final class AuthLoadingLicense extends AuthState{
  AuthLoadingLicense():super();
}

// ignore: must_be_immutable
final class AuthLicenseActive extends AuthState{
  AuthLicenseActive(String? messageToDisplay):super(){
    this.messageToDisplay = messageToDisplay;
  }
}

// ignore: must_be_immutable
final class AuthLicenseNotActive extends AuthState{
  AuthLicenseNotActive(String? messageToDisplay):super(){
    this.messageToDisplay = messageToDisplay;
  }
}