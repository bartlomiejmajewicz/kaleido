part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthWaiting extends AuthEvent{}

final class AuthDeactivateLicense extends AuthEvent{}

final class AuthForceInitialState extends AuthEvent{}

// ignore: must_be_immutable
final class AuthActivateLicense extends AuthEvent{
  String email;
  String licenseCode;
  AuthActivateLicense(this.email, this.licenseCode);
}

// ignore: must_be_immutable
final class AuthActivateLicenseOffline extends AuthEvent{
  String email;
  String licenseCode;
  String licenseStringEncoded;
  String licenseStringIv;
  AuthActivateLicenseOffline(this.email, this.licenseCode, this.licenseStringEncoded, this.licenseStringIv);
}