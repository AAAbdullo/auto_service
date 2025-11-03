import 'package:flutter/material.dart';
import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:auto_service/presentation/widgets/notifications/employee_notification.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  BuildContext? _context;
  BookingProvider? _bookingProvider;
  AuthProvider? _authProvider;

  /// Инициализация менеджера уведомлений
  void init(
    BuildContext context,
    BookingProvider bookingProvider,
    AuthProvider authProvider,
  ) {
    _context = context;
    _bookingProvider = bookingProvider;
    _authProvider = authProvider;
  }

  /// Проверка новых бронирований для текущего сотрудника
  void checkForNewBookings() {
    if (_context == null || _bookingProvider == null || _authProvider == null) {
      return;
    }

    final currentUserPhone = _authProvider!.currentUserPhone;
    if (currentUserPhone == null || !_authProvider!.isServiceEmployee) return;

    final newBookingsCount = _bookingProvider!.getNewBookingsCount(
      currentUserPhone,
    );

    if (newBookingsCount > 0) {
      // Получаем последнее новое бронирование
      final bookings = _bookingProvider!.getBookingsForEmployee(
        currentUserPhone,
      );
      final newBookings = bookings.where((b) => b.isNew).toList();

      if (newBookings.isNotEmpty) {
        final latestBooking = newBookings.first;
        _showBookingNotification(
          latestBooking.productName,
          latestBooking.customerPhone,
        );
      }
    }
  }

  /// Показать уведомление о новом бронировании
  void _showBookingNotification(String productName, String customerPhone) {
    if (_context == null) return;

    EmployeeNotification.showNewBookingAlert(
      _context!,
      productName,
      customerPhone,
    );
  }

  /// Показать диалог с подробностями бронирования
  void showBookingDialog(
    String productName,
    String customerPhone,
    VoidCallback onViewBookings,
  ) {
    if (_context == null) return;

    EmployeeNotification.showBookingDialog(
      _context!,
      productName: productName,
      customerPhone: customerPhone,
      onViewBookings: onViewBookings,
    );
  }

  /// Очистка ресурсов
  void dispose() {
    _context = null;
    _bookingProvider = null;
    _authProvider = null;
  }
}
