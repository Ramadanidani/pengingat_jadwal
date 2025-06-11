class UserModel {
  final String name;
  final String email;
  final String password;

  // Konstruktor untuk membuat instance UserModel
  UserModel({
    required this.name,
    required this.email,
    required this.password,
  });

  // Fungsi untuk mengubah data UserModel menjadi Map yang bisa dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'name' : name,
      'email': email,
      'password': password,
    };
  }

  // Fungsi untuk membuat instance UserModel dari Map (misalnya dari response API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      password: json['password'],
    );
  }
}
