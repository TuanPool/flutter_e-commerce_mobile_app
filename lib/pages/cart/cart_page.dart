import 'package:easy_localization/easy_localization.dart';
import 'package:ecommerece_flutter_app/common/constants/colors.dart';
import 'package:ecommerece_flutter_app/common/constants/sized_box.dart';
import 'package:ecommerece_flutter_app/common/helper/helper.dart';
import 'package:ecommerece_flutter_app/common/widgets/header/header_container.dart';
import 'package:ecommerece_flutter_app/pages/home/home_page.dart';
import 'package:ecommerece_flutter_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../checkout/checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService cartService = CartService();

  int _totalPrice(List<CartItem> items) =>
      items.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: WHeaderContainer.headerContainer(
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: Helper.isDarkMode(context)
                                ? KColors.lightModeColor
                                : KColors.dartModeColor,
                          ),
                        ),
                        KSizedBox.smallWidthSpace,
                        Text(
                          "Your_Cart".tr(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .apply(
                                  color: Helper.isDarkMode(context)
                                      ? KColors.lightModeColor
                                      : Colors.white),
                        )
                      ],
                    ),
                  ),
                  height: 150,
                ),
              ),
              KSizedBox.heightSpace,
              Expanded(
                flex: 5,
                child: StreamBuilder<List<CartItem>>(
                  stream: cartService.getCartItems(AuthService().getUserId()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (AuthService().getUserId() == "") {
                      return const Text('You are not logged in yet');
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text("Giỏ hàng của bạn đang trống"));
                    }

                    final cartItems = snapshot.data!;

                    return ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return infoProductCart(
                          context: context,
                          itemId: item.id,
                          name: item.name,
                          imageUrl: item.imageUrl,
                          total: item.total,
                          priceProduct: item.price,
                          quantity: item.quantity,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Nút dưới cùng chia đôi: Thanh toán toàn bộ & Xóa toàn bộ
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<List<CartItem>>(
              stream: cartService.getCartItems(AuthService().getUserId()),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                final totalPrice = _totalPrice(items);
                return Container(
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (items.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Giỏ hàng trống'.tr())),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutPage.all(items: items),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.payment,
                            color: KColors.primaryColor,
                            size: 24,
                          ),
                          label: Text(
                            "Checkout All",
                            style: TextStyle(
                              color: KColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            cartService.clearCart(AuthService().getUserId());
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 24,
                          ),
                          label: Text(
                            "Delete_all_product".tr(),
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget infoProductCart({
    required BuildContext context,
    required String imageUrl,
    required String name,
    required int priceProduct,
    required int total,
    required String itemId,
    required int quantity,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        width: Helper.screenWidth(context) * 0.95,
        height: Helper.screenHeight(context) * 0.16,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: KColors.dartModeColor.withOpacity(0.1),
              blurRadius: 50,
              spreadRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
          color: Helper.isDarkMode(context)
              ? KColors.dartModeColor.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      KSizedBox.smallHeightSpace,
                      KSizedBox.smallHeightSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Helper.formatCurrency(total),
                            style: const TextStyle(color: Colors.red),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  cartService.removeFromCart(
                                    AuthService().getUserId(),
                                    itemId,
                                    priceProduct,
                                  );
                                },
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                              ),
                              Text(
                                quantity.toString(),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () {
                                  cartService.addToCart(
                                    userId: AuthService().getUserId(),
                                    productId: itemId,
                                    name: name,
                                    price: priceProduct,
                                    imageUrl: imageUrl,
                                  );
                                },
                                icon: const Icon(Icons.add),
                              )
                            ],
                          )
                        ],
                      )
                    ],
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
