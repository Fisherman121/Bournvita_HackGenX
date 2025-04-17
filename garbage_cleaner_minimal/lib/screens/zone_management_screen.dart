import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../services/api_service.dart';

class ZoneManagementScreen extends StatefulWidget {
  const ZoneManagementScreen({Key? key}) : super(key: key);

  @override
  State<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  final ApiService _apiService = ApiService();
  List<Zone> _zones = [];
  bool _isLoading = false;
  String? _selectedZoneId;
  
  @override
  void initState() {
    super.initState();
    _fetchZones();
  }
  
  Future<void> _fetchZones() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final zones = await _apiService.getZones();
      setState(() {
        _zones = zones;
        // Select the first zone by default if none is selected
        if (_selectedZoneId == null && zones.isNotEmpty) {
          _selectedZoneId = zones[0].id;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching zones: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching zones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _setActiveCamera(String zoneId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _apiService.setActiveCamera(zoneId);
      if (success) {
        setState(() {
          _selectedZoneId = zoneId;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera activated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to activate camera'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error setting active camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchZones,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _zones.isEmpty
              ? const Center(child: Text('No zones available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Camera Zones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a camera zone to monitor:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._zones.map((zone) => _buildZoneCard(zone)).toList(),
                      const SizedBox(height: 24),
                      if (_selectedZoneId != null)
                        _buildSelectedZoneDetails(),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildZoneCard(Zone zone) {
    final isSelected = zone.id == _selectedZoneId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            _setActiveCamera(zone.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.videocam,
                  color: isSelected ? Colors.green : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.zoneName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.green : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zone.locationString,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectedZoneDetails() {
    // Find the selected zone
    final selectedZone = _zones.firstWhere(
      (zone) => zone.id == _selectedZoneId,
      orElse: () => Zone(
        id: 'unknown',
        name: 'Unknown Zone',
        description: 'No description available',
        cameraIds: [],
      ),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Active Zone: ${selectedZone.zoneName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zone Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('ID', selectedZone.id),
                _buildDetailRow('Location', selectedZone.locationString),
                _buildDetailRow('Description', selectedZone.description),
                const SizedBox(height: 16),
                const Text(
                  'Status: ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The selected camera is now actively monitoring this zone. Any garbage detected in this zone will be logged and sent to your mobile app for cleaning management.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 