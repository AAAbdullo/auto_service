import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ServiceDetailScreen extends StatelessWidget {
  final AutoServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение сервиса
            if (service.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  service.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.business, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Карточка с основной информацией
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название и рейтинг
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                service.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Описание
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Контактная информация
            _buildSection(
              title: 'contact_info'.tr(),
              icon: Icons.contact_phone,
              child: Column(
                children: [
                  if (service.phone != null)
                    _buildContactItem(
                      icon: Icons.phone,
                      label: 'phone'.tr(),
                      value: service.phone!,
                      onTap: () => _makePhoneCall(service.phone!, context),
                    ),
                  if (service.address != null)
                    _buildContactItem(
                      icon: Icons.location_on,
                      label: 'address'.tr(),
                      value: service.address!,
                      onTap: () => _navigateToMap(
                        service.latitude,
                        service.longitude,
                        context,
                      ),
                    ),
                  if (service.workingHours != null)
                    _buildContactItem(
                      icon: Icons.access_time,
                      label: 'working_hours'.tr(),
                      value: service.workingHours!,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Услуги
            if (service.services.isNotEmpty)
              _buildSection(
                title: 'services'.tr(),
                icon: Icons.build,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: service.services.map((serviceItem) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        serviceItem.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 30),

            // Кнопка "Построить маршрут"
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('🔹 Кнопка "Построить маршрут" нажата');
                  debugPrint(
                    '🔹 Возвращаем координаты: ${service.latitude}, ${service.longitude}',
                  );
                  // Возвращаем координаты через Navigator.pop
                  Navigator.pop(context, {
                    'latitude': service.latitude,
                    'longitude': service.longitude,
                    'buildRoute': true,
                  });
                },
                icon: const Icon(Icons.directions, size: 24),
                label: Text(
                  'build_route'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Номер телефона: $phoneNumber'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(label: 'ОК', onPressed: () {}),
      ),
    );
  }

  /// Переход на карту с построением маршрута
  void _navigateToMap(double latitude, double longitude, BuildContext context) {
    debugPrint('🔹 Адрес нажат, возвращаем координаты: $latitude, $longitude');
    // Используем тот же механизм, что и кнопка "Построить маршрут"
    Navigator.pop(context, {
      'latitude': latitude,
      'longitude': longitude,
      'buildRoute': true,
    });
  }
}
