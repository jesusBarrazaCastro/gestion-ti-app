import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

// Asumiendo que estos imports se resuelven en el proyecto del usuario
import '../../main.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';

// Colores de la paleta para los Cards (ajustados para una apariencia limpia)
const Color _totalColor = Color(0xFFE0F0FF); // Azul claro
const Color _activeColor = Color(0xFFE0FFEE); // Verde claro
const Color _repairColor = Color(0xFFFFF7E0); // Amarillo claro
const Color _inactiveColor = Color(0xFFFFEAEA); // Rojo claro
const Color _totalIconColor = Color(0xFF4285F4);
const Color _activeIconColor = Color(0xFF34A853);
const Color _repairIconColor = Color(0xFFFBBC05);
const Color _inactiveIconColor = Color(0xFFEA4335);


// Widget de Card de Resumen reutilizable
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color valueColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  final String? title;
  const HomeScreen({ Key? key, this.title }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {

  bool _isLoading = false;
  // Los controladores y dropdown ya no se usan en el nuevo diseño del Home,
  // pero los mantengo comentados por si se necesitan más adelante.
  // final TextEditingController _userController = TextEditingController();
  // final TextEditingController _passController = TextEditingController();
  // String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: Colors.black,
        progressIndicator: const CircularProgressIndicator(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de Bienvenida
              Text(
                widget.title ?? 'Dashboard de Gestión TI',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 1. FILA DE CARDS (Inventario de Elementos)
              const Text(
                'Gestión de Elementos de Configuración',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Total Elementos (dummy, basado en la imagen)
                  SummaryCard(
                    title: 'Total Elementos',
                    value: '247',
                    icon: Icons.storage,
                    backgroundColor: _totalColor,
                    iconColor: _totalIconColor,
                    valueColor: Colors.black,
                  ),
                  SizedBox(width: 10),
                  // Activos (dummy, basado en la imagen)
                  SummaryCard(
                    title: 'Activos',
                    value: '189',
                    icon: Icons.check_circle_outline,
                    backgroundColor: _activeColor,
                    iconColor: _activeIconColor,
                    valueColor: _activeIconColor,
                  ),
                  SizedBox(width: 10),
                  // En Reparación (dummy, basado en la imagen)
                  SummaryCard(
                    title: 'En Reparación',
                    value: '32',
                    icon: Icons.build,
                    backgroundColor: _repairColor,
                    iconColor: _repairIconColor,
                    valueColor: _repairIconColor,
                  ),
                  SizedBox(width: 10),
                  // Inactivos (dummy, basado en la imagen)
                  SummaryCard(
                    title: 'Inactivos',
                    value: '26',
                    icon: Icons.cancel,
                    backgroundColor: _inactiveColor,
                    iconColor: _inactiveIconColor,
                    valueColor: _inactiveIconColor,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 2. Sección de Gestión de Incidencias (DUMMY)
              const Text(
                'Gestión de Incidencias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Cards de Incidencias (Dummy)
                  SummaryCard(
                    title: 'Tickets Abiertos',
                    value: '15',
                    icon: Icons.warning_amber,
                    backgroundColor: Color(0xFFF0E0FF),
                    iconColor: Color(0xFF8000FF),
                    valueColor: Color(0xFF8000FF),
                  ),
                  SizedBox(width: 10),
                  SummaryCard(
                    title: 'Pendientes',
                    value: '5',
                    icon: Icons.access_time_filled,
                    backgroundColor: Color(0xFFE0F7FF),
                    iconColor: Color(0xFF05B0FB),
                    valueColor: Color(0xFF05B0FB),
                  ),
                  SizedBox(width: 10),
                  SummaryCard(
                    title: 'Cerrados Hoy',
                    value: '10',
                    icon: Icons.task_alt,
                    backgroundColor: Color(0xFFE0F0E0),
                    iconColor: Color(0xFF008000),
                    valueColor: Color(0xFF008000),
                  ),
                  SizedBox(width: 10),
                  SummaryCard(
                    title: 'Alta Prioridad',
                    value: '3',
                    icon: Icons.notifications_active,
                    backgroundColor: Color(0xFFFFEEEE),
                    iconColor: Color(0xFFC70039),
                    valueColor: Color(0xFFC70039),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 3. Botones de Navegación Rápida
              const Text(
                'Accesos Rápidos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Button(
                    width: 200,
                    text: 'Gestionar Activos',
                    icon: Icons.devices_other,
                    onPressed: () {

                    },
                  ),
                  const SizedBox(width: 10),
                  Button(
                    width: 200,
                    text: 'Ver Incidencias',
                    icon: Icons.report_problem,
                    onPressed: () {

                    },
                  ),
                  const SizedBox(width: 10),
                  Button(
                    width: 200,
                    text: 'Configuraciones',
                    icon: Icons.settings,
                    onPressed: () {

                    },
                  ),
                ],
              ),

            ],
          ),
        )
    );
  }
}