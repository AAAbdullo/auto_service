import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/presentation/providers/cart_provider.dart';
import 'package:auto_service/presentation/providers/orders_provider.dart';
import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:auto_service/presentation/widgets/product_image_widget.dart';
import 'package:auto_service/presentation/widgets/notifications/success_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final int? initialQuantity;
  final bool showActions;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.initialQuantity,
    this.showActions = true,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int quantity;
  bool isAdded = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity ?? 0;
    isAdded = quantity > 0;
  }

  void incrementQuantity() => setState(() {
    quantity++;
    if (quantity > 0) isAdded = true;
  });

  void decrementQuantity() => setState(() {
    if (quantity > 1) {
      quantity--;
    } else {
      quantity = 0;
      isAdded = false;
    }
  });

  @override
  Widget build(BuildContext context) {
    context.watch<CartProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final ordersProvider = context.watch<OrdersProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('product_detail_title'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение товара с Hero анимацией
                  Hero(
                    tag:
                        'product_detail_${widget.product.id ?? DateTime.now().millisecondsSinceEpoch}',
                    child: ProductImageWidget(
                      imageUrl: widget.product.imageUrl,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),

                  // Основная информация
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название и цена
                        Text(
                          widget.product.nameKey?.tr() ?? widget.product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "${widget.product.price.toStringAsFixed(0)} ${'currency'.tr()}",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.green[400]
                                    : Colors.green[700],
                              ),
                            ),
                            if (widget.product.oldPrice != null &&
                                widget.product.oldPrice! >
                                    widget.product.price) ...[
                              const SizedBox(width: 12),
                              Text(
                                "${widget.product.oldPrice!.toStringAsFixed(0)} ${'currency'.tr()}",
                                style: TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Описание
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[850]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'description'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.product.descriptionKey?.tr() ??
                                    widget.product.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Гарантия
                        if (widget.product.warranty != null &&
                            widget.product.warranty!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green[900]?.withValues(alpha: 0.3)
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.green[700]!
                                    : Colors.green[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green[400]
                                      : Colors.green[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'warranty'.tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.green[300]
                                              : Colors.green[900],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.product.warrantyKey?.tr() ??
                                            widget.product.warranty!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.green[400]
                                              : Colors.green[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Преимущества (как на скриншоте)
                        _buildAdvantagesSection(),

                        const SizedBox(height: 24),

                        // Способы оплаты
                        _buildPaymentMethods(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Кнопки снизу
          if (widget.showActions)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// Кнопка "Купить" (если товар не добавлен)
                  if (!isAdded)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isAdded = true;
                            quantity = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          elevation: 2,
                          shadowColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'cart_checkout'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  /// Две кнопки (если товар добавлен)
                  if (isAdded)
                    Row(
                      children: [
                        /// Левая кнопка - выбор количества
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: decrementQuantity,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.red[600],
                                  iconSize: 24,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    quantity.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: incrementQuantity,
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.green[600],
                                  iconSize: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        /// Правая кнопка - оформить заказ
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                final productWithQuantity = widget.product
                                    .copyWith(quantity: quantity);
                                ordersProvider.addOrder(productWithQuantity);

                                // Показываем красивое уведомление
                                SuccessNotification.showOrderSuccess(
                                  context,
                                  widget.product.nameKey?.tr() ??
                                      widget.product.name,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.green.withValues(
                                  alpha: 0.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'cart_checkout'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  /// Кнопка "Бронировать"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final exists = bookingProvider.bookedItems.any(
                          (item) => item.id == widget.product.id,
                        );

                        if (!exists) {
                          // Добавляем в бронирования пользователя
                          bookingProvider.addBooking(widget.product);

                          // Если товар принадлежит сотруднику, создаем детальное бронирование
                          if (widget.product.ownerPhone != null &&
                              widget.product.ownerPhone!.isNotEmpty) {
                            final customerPhone =
                                authProvider.currentUserPhone ?? 'Неизвестно';

                            await bookingProvider.createBookingDetail(
                              product: widget.product,
                              quantity: quantity,
                              customerPhone: customerPhone,
                            );

                            // Показываем уведомление сотруднику (если он сейчас в приложении)
                            // В реальном приложении здесь можно добавить push-уведомления
                            debugPrint(
                              '🔔 Новое бронирование для сотрудника ${widget.product.ownerPhone}: ${widget.product.name}',
                            );
                          }

                          // Simple success message as per user request
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('booking_success_simple'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onTertiary,
                        elevation: 2,
                        shadowColor: Theme.of(
                          context,
                        ).colorScheme.tertiary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'book_now'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Секция преимуществ (как на скриншоте)
  Widget _buildAdvantagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'our_advantages'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAdvantageCard(
                icon: Icons.local_shipping,
                title: 'advantage_free_delivery_title'.tr(),
                description: 'advantage_free_delivery_desc'.tr(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAdvantageCard(
                icon: Icons.build,
                title: 'advantage_expert_installation_title'.tr(),
                description: 'advantage_expert_installation_desc'.tr(),
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAdvantageCard(
          icon: Icons.verified,
          title: 'advantage_quality_guarantee_title'.tr(),
          description: 'advantage_quality_guarantee_desc'.tr(),
          color: Colors.green,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildAdvantageCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Способы оплаты (как на скриншоте)
  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment_methods_title'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPaymentMethod('Payme', Colors.blue[700]!),
                  _buildPaymentMethod('Click', Colors.purple[700]!),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPaymentMethod('Uzcard', Colors.blue[600]!),
                  _buildPaymentMethod('Humo', Colors.cyan[700]!),
                ],
              ),
              const SizedBox(height: 16),
              _buildPaymentMethod(
                'payment_method_cash'.tr(),
                Colors.green[700]!,
              ),
              const SizedBox(height: 16),
              Text(
                'payment_methods_footer'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(String name, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            name == 'Cash' ? Icons.money : Icons.credit_card,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
