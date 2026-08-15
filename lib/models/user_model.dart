class UserModel {
  final int id;
  final String nombre;
  final String apellido;
  final String nombreCompleto;
  final String dni;
  final String? codigo;
  final String correo;
  final String? telefono;
  final String usuario;
  final int tipoUsuario;
  final String tipoUsuarioNombre;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreCompleto,
    required this.dni,
    this.codigo,
    required this.correo,
    this.telefono,
    required this.usuario,
    required this.tipoUsuario,
    required this.tipoUsuarioNombre,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '${json['nombre']} ${json['apellido']}',
      dni: json['dni'] ?? '',
      codigo: json['codigo'],
      correo: json['correo'] ?? '',
      telefono: json['telefono'],
      usuario: json['usuario'] ?? '',
      tipoUsuario: json['tipo_usuario'] is int 
          ? json['tipo_usuario'] 
          : int.parse(json['tipo_usuario']?.toString() ?? '3'),
      tipoUsuarioNombre: json['tipo_usuario_nombre'] ?? 'Usuario',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'nombre_completo': nombreCompleto,
      'dni': dni,
      'codigo': codigo,
      'correo': correo,
      'telefono': telefono,
      'usuario': usuario,
      'tipo_usuario': tipoUsuario,
      'tipo_usuario_nombre': tipoUsuarioNombre,
    };
  }
}
