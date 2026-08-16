import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CrearTramiteScreen extends StatefulWidget {
  const CrearTramiteScreen({Key? key}) : super(key: key);

  @override
  State<CrearTramiteScreen> createState() => _CrearTramiteScreenState();
}

class _CrearTramiteScreenState extends State<CrearTramiteScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _asuntoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoadingUser = true;
  bool _isLoadingTipos = true;
  bool _isLoadingRequisitos = false;
  bool _isSubmitting = false;

  String _siguienteExpediente = 'Cargando...';
  List<dynamic> _tiposTramite = [];
  List<dynamic> _requisitos = [];

  int? _selectedTipoTramite;
  final Map<int, PlatformFile> _selectedFiles = {}; // RequisitoID -> File

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _asuntoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final user = await ApiService.getCurrentUser();
    final tiposResult = await ApiService.getTiposTramite();

    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
        _isLoadingTipos = false;

        if (tiposResult['status'] == 'success' && tiposResult['data'] != null) {
          _siguienteExpediente = tiposResult['data']['siguiente_expediente'] ?? 'TR-001';
          _tiposTramite = tiposResult['data']['tipos_tramite'] ?? [];
        }
      });
    }
  }

  void _onTipoTramiteChanged(int? tipoId) async {
    if (tipoId == null) return;
    setState(() {
      _selectedTipoTramite = tipoId;
      _isLoadingRequisitos = true;
      _requisitos = [];
      _selectedFiles.clear();
    });

    final res = await ApiService.getRequisitosPorTipo(tipoId);

    if (mounted) {
      setState(() {
        _isLoadingRequisitos = false;
        if (res['status'] == 'success' && res['data'] != null) {
          _requisitos = res['data']['requisitos'] ?? [];
          if (res['data']['siguiente_expediente'] != null) {
            _siguienteExpediente = res['data']['siguiente_expediente'];
          }
        }
      });
    }
  }

  void _pickFileForRequisito(int requisitoId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'zip', 'rar', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      setState(() {
        _selectedFiles[requisitoId] = file;
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se encontró la sesión del usuario.")),
      );
      return;
    }

    if (_selectedTipoTramite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona un Tipo de Trámite."), backgroundColor: AppConstants.dangerRed),
      );
      return;
    }

    // Validar que todos los requisitos exigidos tengan un archivo adjunto
    List<String> faltantes = [];
    for (var r in _requisitos) {
      int reqId = r['id'];
      if (!_selectedFiles.containsKey(reqId) || _selectedFiles[reqId]?.path == null) {
        faltantes.add(r['nombre']);
      }
    }

    if (faltantes.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppConstants.warningOrange),
              SizedBox(width: 8),
              Text("Archivos Requeridos"),
            ],
          ),
          content: Text("Debes adjuntar los archivos para los siguientes requisitos obligatorios:\n\n• ${faltantes.join('\n• ')}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            )
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Preparar el mapa de rutas de archivos
    Map<int, String> reqFilesMap = {};
    _selectedFiles.forEach((reqId, pFile) {
      if (pFile.path != null) {
        reqFilesMap[reqId] = pFile.path!;
      }
    });

    final res = await ApiService.crearTramite(
      solicitanteId: _currentUser!.id,
      tipoTramiteId: _selectedTipoTramite!,
      asunto: _asuntoController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      archivosRequisitos: reqFilesMap,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (res['status'] == 'success') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppConstants.successGreen),
              SizedBox(width: 8),
              Text("¡Trámite Registrado!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(res['message'] ?? 'Su solicitud ha sido generada correctamente.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppConstants.primaryBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("N° de Expediente", style: TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                          Text(
                            res['data']?['numeroexpediente'] ?? _siguienteExpediente,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
              onPressed: () {
                Navigator.pop(context); // Cierra diálogo
                Navigator.pop(context); // Vuelve al Dashboard
              },
              child: const Text("ACEPTAR", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: AppConstants.dangerRed),
              SizedBox(width: 8),
              Text("Error al Registrar"),
            ],
          ),
          content: Text(res['message'] ?? 'No se pudo procesar la solicitud.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Text("Nuevo Trámite", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: (_isLoadingUser || _isLoadingTipos)
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitFadingCube(color: AppConstants.primaryNavy, size: 40),
                    SizedBox(height: 16),
                    Text("Cargando formulario de trámite...", style: TextStyle(color: AppConstants.textMuted)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tarjeta N° de Expediente Correlativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppConstants.softShadow,
                          border: Border.all(color: AppConstants.primaryBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.folder_open, color: AppConstants.primaryBlue, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("N° DE EXPEDIENTE ASIGNADO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textMuted)),
                                Text(
                                  _siguienteExpediente,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tarjeta del Formulario Principal
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppConstants.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppConstants.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Datos de la Solicitud",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                            ),
                            const SizedBox(height: 16),

                            // Solicitante (Lectura)
                            TextFormField(
                              initialValue: _currentUser?.nombreCompleto ?? '',
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Solicitante",
                                prefixIcon: const Icon(Icons.person, color: AppConstants.primaryBlue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Select Tipo de Trámite
                            DropdownButtonFormField<int>(
                              value: _selectedTipoTramite,
                              decoration: InputDecoration(
                                labelText: "Tipo de Trámite *",
                                prefixIcon: const Icon(Icons.assignment_outlined, color: AppConstants.primaryBlue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _tiposTramite.map<DropdownMenuItem<int>>((item) {
                                return DropdownMenuItem<int>(
                                  value: item['id'],
                                  child: Text(item['nombre']),
                                );
                              }).toList(),
                              onChanged: _onTipoTramiteChanged,
                              validator: (val) => val == null ? "Selecciona un tipo de trámite." : null,
                            ),
                            const SizedBox(height: 14),

                            // Asunto
                            TextFormField(
                              controller: _asuntoController,
                              decoration: InputDecoration(
                                labelText: "Asunto del Trámite",
                                hintText: "Ej. Solicitud de Constancia de Estudios",
                                prefixIcon: const Icon(Icons.title, color: AppConstants.primaryBlue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Descripción
                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: "Descripción u Observación",
                                hintText: "Escriba aquí detalles adicionales para la mesa de partes...",
                                prefixIcon: const Icon(Icons.notes, color: AppConstants.primaryBlue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sección de Requisitos Exigidos (Si hay un tipo seleccionado)
                      if (_selectedTipoTramite != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppConstants.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppConstants.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.checklist_rtl_rounded, color: AppConstants.primaryNavy),
                                  SizedBox(width: 8),
                                  Text(
                                    "Requisitos Obligatorios",
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Debes adjuntar un archivo para cada requisito listado a continuación:",
                                style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                              ),
                              const SizedBox(height: 14),

                              if (_isLoadingRequisitos)
                                const Center(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: SpinKitThreeBounce(color: AppConstants.primaryBlue, size: 24),
                                )
                              else if (_requisitos.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: const Text(
                                    "Este tipo de trámite no requiere archivos de requisitos obligatorios.",
                                    style: TextStyle(color: Colors.brown, fontSize: 13),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _requisitos.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final req = _requisitos[index];
                                    int reqId = req['id'];
                                    bool hasFile = _selectedFiles.containsKey(reqId);
                                    PlatformFile? file = _selectedFiles[reqId];

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: hasFile ? AppConstants.successGreen.withOpacity(0.06) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hasFile ? AppConstants.successGreen.withOpacity(0.4) : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                hasFile ? Icons.check_circle : Icons.error_outline,
                                                color: hasFile ? AppConstants.successGreen : AppConstants.dangerRed,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  req['nombre'],
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (req['descripcion'] != null && req['descripcion'].toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 28, top: 4),
                                              child: Text(
                                                req['descripcion'],
                                                style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const SizedBox(width: 28),
                                              ElevatedButton.icon(
                                                onPressed: () => _pickFileForRequisito(reqId),
                                                icon: Icon(hasFile ? Icons.refresh : Icons.attach_file, size: 16),
                                                label: Text(hasFile ? "Cambiar Archivo" : "Adjuntar Archivo"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: hasFile ? AppConstants.primaryNavy : AppConstants.primaryBlue,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              if (hasFile && file != null)
                                                Expanded(
                                                  child: Text(
                                                    file.name,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.successGreen),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botón Enviar Trámite
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SpinKitThreeBounce(color: Colors.white, size: 22)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "REGISTRAR TRÁMITE",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
