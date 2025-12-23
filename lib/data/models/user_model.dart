class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isAdmin;
  final String? preferredTheme;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.isAdmin = false,
    this.preferredTheme,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['name'],
      photoURL: map['photoURL'] ?? map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      preferredTheme: map['preferredTheme'],
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isAdmin': isAdmin,
      'preferredTheme': preferredTheme,
    };
  }

  // From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      isAdmin: json['isAdmin'] ?? false,
      preferredTheme: json['preferredTheme'],
    );
  }
}
