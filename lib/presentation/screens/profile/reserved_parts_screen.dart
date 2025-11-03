import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ReservedPartsScreen extends StatelessWidget {
  const ReservedPartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final reservedParts = bookingProvider.bookedItems;

    return Scaffold(
      appBar: AppBar(title: Text('booked_parts'.tr()), centerTitle: true),
      body: reservedParts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_booked_parts'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_booked_parts_subtitle'.tr(),
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservedParts.length,
              itemBuilder: (context, index) {
                final item = reservedParts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Image.network(
                      item.imageUrl ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text('${item.price.toStringAsFixed(2)} \$'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        bookingProvider.removeBooking(item.id);
                      },
                    ),
                    onTap: () {
                      // Можно открыть детали продукта, если нужно
                    },
                  ),
                );
              },
            ),
    );
  }
}
