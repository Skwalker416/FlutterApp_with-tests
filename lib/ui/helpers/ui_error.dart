enum UIError {
  requiredField,
  invalidField,
  unexpected,
  invalidCredentials,
  emailInUse,
  invalidEmail,
  invalidMessageNewPost
}

extension UIErrorExtension on UIError {
  String get description {
    switch (this) {
      case UIError.requiredField:
        return 'መሞላት ያለበት';
      case UIError.invalidField:
        return 'ልክ ያልሆነ መስክ';
      case UIError.invalidCredentials:
        return 'ልክ ያልሆኑ ምስክርነቶች';
      case UIError.emailInUse:
        return 'ኢሜይል አስቀድሞ ጥቅም ላይ ውሏል';
      case UIError.invalidEmail:
        return 'የማይሰራ E-mail';
      case UIError.invalidMessageNewPost:
        return 'መልእክት ከተፈቀደው በላይ ይበልጣል';
      default:
        return 'የሆነ ስህተት ተከስቷል. እባክዎ በቅርቡ እንደገና ይሞክሩ';
    }
  }
}
