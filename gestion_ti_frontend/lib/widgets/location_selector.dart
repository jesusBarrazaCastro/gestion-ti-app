import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/utilities/dialog_util.dart';
import 'package:gestion_ti_frontend/widgets/location_selection_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utilities/msg_util.dart';

typedef LocationData = Map<String, dynamic>;

class LocationController {
  LocationData? _selectedLocation;

  LocationController({LocationData? initialLocation}) {
    _selectedLocation = initialLocation;
  }

  LocationData? getLocation() {
    return _selectedLocation;
  }

  void setLocation(LocationData? newLocation) {
    _selectedLocation = newLocation;
  }
}

class LocationFilterWidget extends StatefulWidget {
  final LocationController controller;
  final VoidCallback onLocationChanged;
  final bool? isSelection;

  const LocationFilterWidget({
    super.key,
    required this.controller,
    required this.onLocationChanged, this.isSelection = false,
  });

  @override
  State<LocationFilterWidget> createState() => _LocationFilterWidgetState();
}

class _LocationFilterWidgetState extends State<LocationFilterWidget> {

  void _openLocationSelection() async {
    final newLocation = await DialogUtil.showCustomDialog(
      context: context,
      height: 500,
      width: 500,
      title: 'Seleccionar ubicación',
      showCloseButton: true,
      child: LocationSelectionDialog(initialLocation: widget.controller.getLocation(), isSelection: widget.isSelection,)
    );

    if (newLocation != null) {
      widget.controller.setLocation(newLocation);
      widget.onLocationChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.controller.getLocation();

    final String displayText = location == null
        ? 'Seleccionar Ubicación...'
        : '${location['departamento_id'] != null ? 'Departamento de ' : ''}${location['departamento_nombre']} - ${location['edificio_nombre']} - ${location['ubicacion_nombre']}';

    return InkWell(
      onTap: _openLocationSelection,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey, width: 2.0),
            color: Colors.white
        ),
        child: Container(
          height: 40,
          //width: 530,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.place, color: Colors.black,),
              const SizedBox(width: 5,),
              Expanded(
                child: Text(
                  displayText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: location == null ? Colors.grey : Colors.black,
                    fontStyle: location == null ? FontStyle.italic : null,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey)
            ],
          ),
        ),
      ),
    );
  }
}


