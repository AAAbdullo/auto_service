import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/data/models/booking_details_model.dart';
import 'package:auto_service/data/models/market_model.dart';
import 'package:auto_service/data/datasources/remote/market_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingProvider with ChangeNotifier {
  // ===== ЛОКАЛЬНЫЕ БРОНИ (как было) =====
  final List<ProductModel> _bookedItems = [];
  final List<BookingDetailsModel> _bookingDetails = [];
  static const String _keyBookingDetails = 'booking_details';

  List<ProductModel> get bookedItems => List.unmodifiable(_bookedItems);
  List<BookingDetailsModel> get bookingDetails =>
      List.unmodifiable(_bookingDetails);

  // ===== BACKEND БРОНИ (через API) =====
  final MarketApiService _apiService = MarketApiService();
  List<ProductReservation> _reservations = [];
  bool _isLoading = false;
  String? _error;

  List<ProductReservation> get reservations => List.unmodifiable(_reservations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Инициализация - загрузка бронирований из памяти
  Future<void> init() async {
    await _loadBookingDetails();
  }

  /// Загрузить список бронирований с backend
  Future<void> fetchReservations(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final reservations = await _apiService.getMyReservations(token);
      debugPrint(
        '🌐 [Booking/API] fetched reservations: count=${reservations.length}',
      );
      // Для дебага можно вывести первые несколько элементов
      if (reservations.isNotEmpty) {
        debugPrint(
          '🌐 [Booking/API] first reservation sample: '
          '${reservations.first.id}, status=${reservations.first.status}',
        );
      }
      _reservations = reservations;
    } catch (e) {
      debugPrint('❌ [Booking/API] error fetching reservations: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Обновить статус бронирования на backend
  Future<bool> updateStatus({
    required String token,
    required int reservationId,
    required String status, // pending | confirmed | cancelled
  }) async {
    debugPrint(
      '🌐 [Booking/API] updateStatus id=$reservationId -> $status',
    );
    final result = await _apiService.updateReservationStatus(
      token: token,
      reservationId: reservationId,
      status: status,
    );
    debugPrint(
      '🌐 [Booking/API] updateStatus result=$result, refreshing list…',
    );
    if (result) {
      await fetchReservations(token);
    }
    return result;
  }

  /// Загрузка детальных бронирований из SharedPreferences
  Future<void> _loadBookingDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keyBookingDetails);

      debugPrint('📦 [Booking] load from prefs, raw="$jsonString"');

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _bookingDetails
          ..clear()
          ..addAll(
            jsonList
                .map((json) => BookingDetailsModel.fromJson(json))
                .toList(),
          );
        debugPrint(
          '✅ [Booking] loaded ${_bookingDetails.length} items from local storage',
        );
      }
      // ignore: empty_catches
    } catch (e) {
      debugPrint('❌ [Booking] error loading from prefs: $e');
    }
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
      debugPrint(
        '💾 [Booking] saved ${_bookingDetails.length} items to prefs, length=${jsonString.length}',
      );
      // ignore: empty_catches
    } catch (e) {
      debugPrint('❌ [Booking] error saving to prefs: $e');
    }
  }

  /// Добавить бронирование (для обычных пользователей, локально)
  void addBooking(ProductModel product) {
    if (!_bookedItems.any((item) => item.id == product.id)) {
      _bookedItems.add(product);
      debugPrint(
        '📝 [Booking] added simple booking for product id=${product.id}, name=${product.name}',
      );
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
      productId: product.id?.toString() ?? '',
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

    debugPrint(
      '🆕 [Booking] create detail: productId=${booking.productId}, '
      'employee=${booking.employeePhone}, customer=${booking.customerPhone}, '
      'qty=${booking.quantity}, total=$totalPrice',
    );

    _bookingDetails.add(booking);
    await _saveBookingDetails();
    notifyListeners();
  }

  /// Получить бронирования для конкретного сотрудника
  List<BookingDetailsModel> getBookingsForEmployee(String employeePhone) {
    final list = _bookingDetails
        .where((booking) => booking.employeePhone == employeePhone)
        .toList()
      ..sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    debugPrint(
      '📊 [Booking] getBookingsForEmployee "$employeePhone" => ${list.length} items',
    );
    return list;
  }

  /// Получить количество новых бронирований для сотрудника
  int getNewBookingsCount(String employeePhone) {
    final count = _bookingDetails
        .where(
          (booking) => booking.employeePhone == employeePhone && booking.isNew,
        )
        .length;
    debugPrint(
      '🔔 [Booking] getNewBookingsCount "$employeePhone" => $count',
    );
    return count;
  }

  /// Отметить бронирование как просмотренное
  Future<void> markAsViewed(String bookingId) async {
    final index = _bookingDetails.indexWhere(
      (booking) => booking.id == bookingId,
    );
    if (index != -1) {
      _bookingDetails[index] = _bookingDetails[index].copyWith(isNew: false);
      debugPrint('👁 [Booking] markAsViewed id=$bookingId');
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
    debugPrint(
      '👁 [Booking] markAllAsViewedForEmployee "$employeePhone", changed=$hasChanges',
    );
    if (hasChanges) {
      await _saveBookingDetails();
      notifyListeners();
    }
  }

  /// Удалить бронирование
  Future<void> removeBookingDetail(String bookingId) async {
    _bookingDetails.removeWhere((booking) => booking.id == bookingId);
    debugPrint('🗑 [Booking] removeBookingDetail id=$bookingId');
    await _saveBookingDetails();
    notifyListeners();
  }

  void removeBooking(String id) {
    _bookedItems.removeWhere((item) => item.id == id);
    debugPrint('🗑 [Booking] remove simple booking id=$id');
    notifyListeners();
  }

  /// (Необязательно) — очистить все брони
  void clearBookings() {
    _bookedItems.clear();
    _bookingDetails.clear();
    debugPrint('🧹 [Booking] clear all bookings (simple + detailed)');
    _saveBookingDetails();
    // backend-список не трогаем, он обновится при следующем fetchReservations
    notifyListeners();
  }
}
