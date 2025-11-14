import 'package:easy_localization/easy_localization.dart';
import 'package:ecommerece_flutter_app/pages/checkout/payment_success.dart';
import 'package:ecommerece_flutter_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_flutter_app/pages/checkout/addAddress.dart';
import 'package:ecommerece_flutter_app/models/cart_item.dart';
import 'package:ecommerece_flutter_app/common/constants/colors.dart';
import 'package:ecommerece_flutter_app/common/helper/helper.dart';

import '../../models/address_model.dart';
import '../../services/checkout_service.dart';
import '../../services/notification_service.dart';
// >>> thêm để xóa giỏ khi thanh toán toàn bộ
import '../../services/cart_service.dart';

class CheckoutPage extends StatefulWidget {
  // mở rộng: có thể là 1 item (luồng cũ) hoặc nhiều item (toàn bộ giỏ)
  final CartItem? cartItem; // dùng khi mua 1 sản phẩm (luồng cũ)
  final double? totalPrice; // tổng tiền của 1 sản phẩm (luồng cũ)
  final List<CartItem>? items; // dùng khi thanh toán toàn bộ giỏ

  // Luồng cũ: giữ nguyên cách gọi hiện có
  const CheckoutPage({
    Key? key,
    required this.cartItem,
    required this.totalPrice,
    this.items,
  }) : super(key: key);

  // Luồng mới: thanh toán toàn bộ giỏ bằng 1 đơn duy nhất
  const CheckoutPage.all({
    Key? key,
    required List<CartItem> items,
  })  : cartItem = null,
        totalPrice = null,
        items = items,
        super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Address? _selectedAddress;
  String _paymentMethod = "Cash_on_delivery".tr();
  final AddressService _addressService = AddressService();

  void _navigateToAddAddress() async {
    final newAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressPage()),
    );

    if (newAddress != null) {
      setState(() {
        _selectedAddress = newAddress;
      });
    }
  }

  bool get _isAllCart =>
      widget.items != null && (widget.items?.isNotEmpty ?? false);

  int get _grandTotal {
    if (_isAllCart) {
      return widget.items!.fold(0, (s, e) => s + e.total);
    }
    return (widget.totalPrice ?? 0).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAllCart ? 'Thanh toán toàn bộ' : "Check_Out".tr()),
        elevation: 1,
        iconTheme: IconThemeData(
            color: Helper.isDarkMode(context)
                ? KColors.dartModeColor
                : Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Danh sách sản phẩm
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Product".tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_isAllCart)
                          ...widget.items!.map(_buildCartItem)
                        else
                          _buildCartItem(widget.cartItem!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Địa chỉ giao hàng
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: KColors.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _selectedAddress != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "${_selectedAddress!.name} - ${_selectedAddress!.phone}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    Text(
                                        "${_selectedAddress!.detail}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.province}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge),
                                  ],
                                )
                              : Text("add_address_empty".tr()),
                        ),
                        GestureDetector(
                          onTap: _showAddressSelectionDialog,
                          child: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Phương thức thanh toán
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment".tr(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          items: [
                            "Cash_on_delivery".tr(),
                            "Visa".tr(),
                          ]
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Thanh toán
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total".tr(),
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      Helper.formatCurrency(_grandTotal),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KColors.primaryColor),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KColors.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: Text(
                    _isAllCart ? 'Place_Order'.tr() : "Place_Order".tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressSelectionDialog() async {
    final addresses = await _addressService.getAddresses();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select_Address".tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return ListTile(
                  title: Text(address.name),
                  subtitle: Text(address.fullAddress),
                  onTap: () {
                    setState(() {
                      _selectedAddress = address;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel".tr()),
            ),
            TextButton(
              onPressed: _navigateToAddAddress,
              child: Text("Add_New_Address".tr()),
            ),
          ],
        );
      },
    );
  }

  void _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please_add_shipping_address!".tr())),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm_Order".tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Confirm_notification".tr()),
              const SizedBox(height: 16),
              Text(
                  "total_price".tr(args: [Helper.formatCurrency(_grandTotal)])),
              const SizedBox(height: 8),
              Text("payment_method".tr(namedArgs: {"method": _paymentMethod})),
              const SizedBox(height: 8),
              Text("address"
                  .tr(namedArgs: {"address": _selectedAddress!.fullAddress})),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel".tr()),
            ),
            TextButton(
              onPressed: () async {
                final userId = AuthService().getUserId();
                final orderedCol = FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('ordered');

                if (_isAllCart) {
                  // Ghi 1 đơn DUY NHẤT với mảng items[]
                  final items = widget.items!
                      .map((it) => {
                            "productId": it.id,
                            "name": it.name,
                            "imageUrl": it.imageUrl,
                            "price": it.price,
                            "quantity": it.quantity,
                            "lineTotal": it.total,
                          })
                      .toList();

                  await orderedCol.add({
                    "address": _selectedAddress!.toMap(),
                    "paymentMethod": _paymentMethod,
                    "totalPrice": _grandTotal,
                    "status": "Pending",
                    "items": items,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  // clear giỏ sau khi tạo 1 đơn tổng
                  await CartService().clearCart(userId);

                  await NotificationService.addNotification(userId,
                      "Bạn đã đặt đơn hàng thành công (${items.length} sản phẩm). Cảm ơn bạn!");
                } else {
                  // Hành vi CŨ: 1 sản phẩm -> field 'product'
                  await orderedCol.add({
                    "address": _selectedAddress!.toMap(),
                    "paymentMethod": _paymentMethod,
                    "totalPrice": widget.totalPrice,
                    "status": "Pending",
                    "product": {
                      "name": widget.cartItem!.name,
                      "imageUrl": widget.cartItem!.imageUrl,
                      "price": widget.cartItem!.price,
                      "quantity": widget.cartItem!.quantity,
                      "total": widget.cartItem!.total,
                    },
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  await NotificationService.addNotification(userId,
                      "You have successfully ordered ${widget.cartItem!.name}! Thank you!");
                }

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PaymentSuccessScreen()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Check_Out_Success".tr())),
                );
              },
              child: Text("Confirm".tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return ListTile(
      leading: Image.network(item.imageUrl,
          width: 50, height: 50, fit: BoxFit.cover),
      title:
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Quantity: ${item.quantity}"),
      trailing: Text(
        Helper.formatCurrency(item.total.toInt()),
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: KColors.primaryColor),
      ),
    );
  }
}
