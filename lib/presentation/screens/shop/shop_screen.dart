import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/presentation/providers/cart_provider.dart';
import 'package:auto_service/presentation/providers/language_provider.dart';
import 'package:auto_service/presentation/providers/products_provider.dart';
import 'package:auto_service/presentation/screens/cart/cart_screen.dart';
import 'package:auto_service/presentation/screens/shop/product_detail_screen.dart';
import 'package:auto_service/presentation/widgets/product_image_widget.dart';
import 'package:auto_service/core/utils/responsive_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final cart = context.watch<CartProvider>();
        final productsProvider = context.watch<ProductsProvider>();

        // Демо-товары (базовые)
        final List<ProductModel> demoProducts = [
          ProductModel(
            id: 'demo_1',
            name: 'brake_pad'.tr(),
            nameKey: 'brake_pad',
            price: 250000,
            description: 'brake_pad_desc'.tr(),
            descriptionKey: 'brake_pad_desc',
            warranty: '6_month_warranty',
            warrantyKey: '6_month_warranty',
            imageUrl: 'https://picsum.photos/400/300?random=1',
            brand: 'Auto Service №1',
            category: 'Remont',
            rating: 4.7,
            quantity: 15,
            inStock: true,
          ),
          ProductModel(
            id: 'demo_2',
            name: 'engine_oil'.tr(),
            nameKey: 'engine_oil',
            price: 120000,
            description: 'engine_oil_desc'.tr(),
            descriptionKey: 'engine_oil_desc',
            warranty: '6_month_warranty',
            warrantyKey: '6_month_warranty',
            imageUrl: 'https://picsum.photos/400/300?random=2',
            brand: 'Auto Shop 24/7',
            category: 'Dvigatel',
            rating: 4.7,
            quantity: 23,
            inStock: true,
          ),
          ProductModel(
            id: 'demo_3',
            name: 'battery'.tr(),
            nameKey: 'battery',
            price: 550000,
            description: 'battery_desc'.tr(),
            descriptionKey: 'battery_desc',
            warranty: '6_month_warranty',
            warrantyKey: '6_month_warranty',
            imageUrl: 'https://picsum.photos/400/300?random=3',
            brand: 'Servis AvtoPlus',
            category: 'Dvigatel',
            rating: 4.7,
            quantity: 7,
            inStock: true,
          ),
        ];

        // Товары от сотрудников
        final employeeProducts = productsProvider.getAllProducts();

        // Объединяем все товары
        final List<ProductModel> products = [
          ...demoProducts,
          ...employeeProducts,
        ];

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.grey[100],
          appBar: AppBar(
            title: Text('shop_title'.tr()),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            actions: [
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 12,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Адаптивный расчет размеров для разных экранов
              final screenWidth = MediaQuery.of(context).size.width;
              final isVerySmallScreen = screenWidth < 320;
              final isSmallScreen = screenWidth < 360;

              // Адаптивные отступы и промежутки
              double padding, spacing, aspectRatio;
              if (isVerySmallScreen) {
                padding = 12.0; // 6*2
                spacing = 12.0; // 6*2
                aspectRatio = 1.3; // Очень компактно
              } else if (isSmallScreen) {
                padding = 16.0; // 8*2
                spacing = 16.0; // 8*2
                aspectRatio = 1.4; // Компактно
              } else {
                padding = 24.0; // 12*2
                spacing = 24.0; // 12*2
                aspectRatio = 1.55; // Обычно
              }

              final itemWidth = (constraints.maxWidth - padding - spacing) / 2;
              final itemHeight = itemWidth * aspectRatio;

              return GridView.builder(
                padding: EdgeInsets.all(
                  padding / 2,
                ), // Используем рассчитанные значения
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing:
                      spacing / 2, // Используем рассчитанные значения
                  crossAxisSpacing: spacing / 2,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productModel = products[index];
                  final isInCart = cart.isInCart(productModel.id);

                  return RepaintBoundary(
                    key: ValueKey(productModel.id),
                    child: _ProductCard(
                      product: productModel,
                      isInCart: isInCart,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: productModel),
                          ),
                        );
                      },
                      onAddToCart: () {
                        cart.addItemWithQuantity(productModel, 1);
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// Оптимизированный виджет карточки товара
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isInCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.isInCart,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Изображение с Hero анимацией
            Flexible(
              flex: 5,
              child: Stack(
                children: [
                  Hero(
                    tag: product.id,
                    child: ProductImageWidget(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  // Бейдж с рейтингом (компактный)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4, // Уменьшил отступы
                        vertical: 2, // Уменьшил отступы
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(
                          8,
                        ), // Уменьшил радиус
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2, // Уменьшил размытие
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 10,
                          ), // Уменьшил размер
                          const SizedBox(width: 2), // Уменьшил отступ
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  ResponsiveText.caption(context).fontSize! *
                                  0.7, // Адаптивный размер
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Информация о товаре
            Flexible(
              flex: 4, // Уменьшил flex для компактности
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  8,
                  6,
                  8,
                  4,
                ), // Уменьшил отступы
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Равномерное распределение
                  children: [
                    // Название товара
                    Text(
                      product.nameKey?.tr() ?? product.name,
                      style: ResponsiveText.caption(context).copyWith(
                        fontWeight: FontWeight.w600, // Уменьшил жирность
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.1, // Уменьшил межстрочный интервал
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Небольшой отступ вместо Spacer
                    // Цена
                    Text(
                      "${product.price.toStringAsFixed(0)} ${'currency'.tr()}",
                      style: ResponsiveText.body(context).copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[400]
                            : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize:
                            ResponsiveText.body(context).fontSize! *
                            0.9, // Немного меньше
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Кнопка "Добавить в корзину"
            Padding(
              padding: const EdgeInsets.fromLTRB(
                8,
                4,
                8,
                8,
              ), // Уменьшил отступы
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isInCart ? null : onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInCart
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]
                              : Colors.grey[400])
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: isInCart
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.white)
                        : Theme.of(context).colorScheme.onPrimary,
                    elevation: isInCart ? 0 : 1, // Уменьшил тень
                    shadowColor: isInCart
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // Уменьшил горизонтальные отступы
                      vertical: 8, // Уменьшил вертикальные отступы
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Уменьшил радиус
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isInCart
                              ? Icons.check_circle
                              : Icons.add_shopping_cart,
                          size: 12, // Уменьшил размер иконки
                        ),
                        const SizedBox(width: 3), // Уменьшил отступ
                        Text(
                          isInCart ? 'in_cart'.tr() : 'add_to_cart'.tr(),
                          style: TextStyle(
                            fontSize:
                                ResponsiveText.caption(context).fontSize! *
                                0.9, // Адаптивный размер
                            fontWeight: FontWeight.w600, // Уменьшил жирность
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
