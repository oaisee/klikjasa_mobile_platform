import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget untuk menampilkan dashboard monitoring perubahan pengaturan penting
class AppConfigMonitoringDashboard extends StatefulWidget {
  const AppConfigMonitoringDashboard({super.key});

  @override
  State<AppConfigMonitoringDashboard> createState() => _AppConfigMonitoringDashboardState();
}

class _AppConfigMonitoringDashboardState extends State<AppConfigMonitoringDashboard> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  // Filter
  String? _selectedKey;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Data
  List<Map<String, dynamic>> _configChangeLogs = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadConfigChangeLogs();
  }
  
  Future<void> _loadConfigChangeLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Buat query dasar
      var query = _supabaseClient.from('app_config_change_logs').select();
      
      // Terapkan filter
      if (_selectedKey != null) {
        query = query.eq('key', _selectedKey as String);
      }
      
      if (_startDate != null) {
        query = query.gte('changed_at', _startDate!.toIso8601String());
      }
      
      if (_endDate != null) {
        // Tambahkan 1 hari ke end date untuk mencakup seluruh hari
        final endDatePlus = _endDate!.add(const Duration(days: 1));
        query = query.lt('changed_at', endDatePlus.toIso8601String());
      }
      
      // Urutkan berdasarkan waktu perubahan terbaru
      final orderedQuery = query.order('changed_at', ascending: false);
      
      // Batasi jumlah hasil
      final limitedQuery = orderedQuery.limit(100);
      
      final result = await limitedQuery;
      
      setState(() {
        _configChangeLogs = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<List<String>> _loadAvailableKeys() async {
    try {
      final result = await _supabaseClient
          .from('app_config_change_logs')
          .select('key')
          .order('key')
          .limit(100);
      
      final keys = <String>{};
      for (final item in result) {
        keys.add(item['key'] as String);
      }
      
      return keys.toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Pengaturan Aplikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfigChangeLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _buildLogsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _loadAvailableKeys(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    
                    final keys = snapshot.data ?? [];
                    
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Pengaturan',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedKey,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Semua Pengaturan'),
                        ),
                        ...keys.map((key) => DropdownMenuItem<String>(
                          value: key,
                          child: Text(key),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedKey = value;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Mulai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
                        : '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Akhir',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                        : '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_alt),
                label: const Text('Terapkan Filter'),
                onPressed: _loadConfigChangeLogs,
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Reset Filter'),
                onPressed: () {
                  setState(() {
                    _selectedKey = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadConfigChangeLogs();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogsList() {
    if (_configChangeLogs.isEmpty) {
      return const Center(
        child: Text('Tidak ada data perubahan pengaturan'),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tanggal & Waktu')),
          DataColumn(label: Text('Pengaturan')),
          DataColumn(label: Text('Nilai Lama')),
          DataColumn(label: Text('Nilai Baru')),
          DataColumn(label: Text('Diubah Oleh')),
        ],
        rows: _configChangeLogs.map((log) {
          final changedAt = DateTime.parse(log['changed_at']);
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(changedAt);
          
          return DataRow(
            cells: [
              DataCell(Text(formattedDate)),
              DataCell(Text(log['key'])),
              DataCell(Text(log['old_value'])),
              DataCell(Text(log['new_value'])),
              DataCell(Text(log['changed_by'])),
            ],
          );
        }).toList(),
      ),
    );
  }
}
