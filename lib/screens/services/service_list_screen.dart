import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/service.dart';
import '../../providers/service_provider.dart';
import '../../widgets/common/custom_text_field.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _searchController = TextEditingController();
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  List<String>? _selectedAreas;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    Provider.of<ServiceProvider>(context, listen: false).loadServices(
      search: _searchController.text,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      areaLayanan: _selectedAreas,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Layanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price Range
              const Text('Rentang Harga'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minPrice = double.tryParse(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxPrice = double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Rating
              const Text('Rating Minimum'),
              Slider(
                value: _minRating ?? 0,
                min: 0,
                max: 5,
                divisions: 5,
                label: '${_minRating ?? 0}',
                onChanged: (value) {
                  setState(() {
                    _minRating = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadServices();
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Cari Layanan',
                  hint: 'Masukkan nama layanan...',
                  controller: _searchController,
                  validator: null,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list),
                color: AppColors.primary,
              ),
            ],
          ),
        ),

        // Service List
        Expanded(
          child: Consumer<ServiceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(child: Text(provider.error!));
              }

              if (provider.services.isEmpty) {
                return const Center(child: Text('Tidak ada layanan tersedia'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.services.length,
                itemBuilder: (context, index) {
                  final service = provider.services[index];
                  return _ServiceListItem(service: service);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ServiceListItem extends StatelessWidget {
  final Service service;

  const _ServiceListItem({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to service detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Service Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(service.images.first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Rp ${service.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${service.totalReviews})',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
