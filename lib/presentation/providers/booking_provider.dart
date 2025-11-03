import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/data/models/booking_details_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingProvider with ChangeNotifier {
  final List<ProductModel> _bookedItems = [];
  final List<BookingDetailsModel> _bookingDetails = [];
  static const String _keyBookingDetails = 'booking_details';

  List<ProductModel> get bookedItems => List.unmodifiable(_bookedItems);
  List<BookingDetailsModel> get bookingDetails =>
      List.unmodifiable(_bookingDetails);

  /// Инициализация - загрузка бронирований из памяти
  Future<void> init() async {
    await _loadBookingDetails();
  }

  /// Загрузка детальных бронирований из SharedPreferences
  Future<void> _loadBookingDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keyBookingDetails);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _bookingDetails.clear();
        _bookingDetails.addAll(
          jsonList.map((json) => BookingDetailsModel.fromJson(json)).toList(),
        );
      }
      // ignore: empty_catches
    } catch (e) {}
    notifyListeners();
  }

  /// Сохранение детальных бронирований в SharedPreferences
  Future<void> _saveBookingDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(
        _bookingDetails.map((booking) => booking.toJson()).toList(),
      );
      await prefs.setString(_keyBookingDetails, jsonString);
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Добавить бронирование (для обычных пользователей)
  void addBooking(ProductModel product) {
    if (!_bookedItems.any((item) => item.id == product.id)) {
      _bookedItems.add(product);
      notifyListeners();
    }
  }

  /// Создать детальное бронирование (когда пользователь бронирует товар сотрудника)
  Future<void> createBookingDetail({
    required ProductModel product,
    required int quantity,
    required String customerPhone,
  }) async {
    // Создаем уникальный ID для бронирования
    final bookingId = '${product.id}_${DateTime.now().millisecondsSinceEpoch}';
    final totalPrice = product.price * quantity;

    final booking = BookingDetailsModel(
      id: bookingId,
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      quantity: quantity,
      pricePerUnit: product.price,
      totalPrice: totalPrice,
      customerPhone: customerPhone,
      employeePhone: product.ownerPhone ?? '',
      bookedAt: DateTime.now(),
      isNew: true,
    );

    _bookingDetails.add(booking);
    await _saveBookingDetails();
    notifyListeners();
  }

  /// Получить бронирования для конкретного сотрудника
  List<BookingDetailsModel> getBookingsForEmployee(String employeePhone) {
    return _bookingDetails
        .where((booking) => booking.employeePhone == employeePhone)
        .toList()
      ..sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
  }

  /// Получить количество новых бронирований для сотрудника
  int getNewBookingsCount(String employeePhone) {
    return _bookingDetails
        .where(
          (booking) => booking.employeePhone == employeePhone && booking.isNew,
        )
        .length;
  }

  /// Отметить бронирование как просмотренное
  Future<void> markAsViewed(String bookingId) async {
    final index = _bookingDetails.indexWhere(
      (booking) => booking.id == bookingId,
    );
    if (index != -1) {
      _bookingDetails[index] = _bookingDetails[index].copyWith(isNew: false);
      await _saveBookingDetails();
      notifyListeners();
    }
  }

  /// Отметить все бронирования сотрудника как просмотренные
  Future<void> markAllAsViewedForEmployee(String employeePhone) async {
    bool hasChanges = false;
    for (int i = 0; i < _bookingDetails.length; i++) {
      if (_bookingDetails[i].employeePhone == employeePhone &&
          _bookingDetails[i].isNew) {
        _bookingDetails[i] = _bookingDetails[i].copyWith(isNew: false);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      await _saveBookingDetails();
      notifyListeners();
    }
  }

  /// Удалить бронирование
  Future<void> removeBookingDetail(String bookingId) async {
    _bookingDetails.removeWhere((booking) => booking.id == bookingId);
    await _saveBookingDetails();
    notifyListeners();
  }

  void removeBooking(String id) {
    _bookedItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// ✅ Добавлен корректный метод подтверждения брони
  void confirmBooking(String id) {
    _bookedItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// (Необязательно) — очистить все брони
  void clearBookings() {
    _bookedItems.clear();
    notifyListeners();
  }
}
