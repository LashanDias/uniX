import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/food_order_service.dart';
import '../../widgets/app_back_button.dart';

/// Review the cart and place the order.
class FoodCartScreen extends StatefulWidget {
  const FoodCartScreen({super.key});

  @override
  State<FoodCartScreen> createState() => _FoodCartScreenState();
}

class _FoodCartScreenState extends State<FoodCartScreen> {
  final _note = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _placing = true);
    try {
      final order = await FoodOrderService.placeOrder(note: _note.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order placed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${order.restaurantName}\n'),
              for (final line in order.lines) Text(line),
              const SizedBox(height: 10),
              Text(
                'Total: Rs. ${order.total.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              const Text('Show this code at the counter:'),
              const SizedBox(height: 4),
              Text(
                order.collectionCode,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pay at the counter when you collect. No payment has been '
                'taken in the app.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not place the order. Please retry.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Your order'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ValueListenableBuilder<List<OrderLine>>(
            valueListenable: FoodOrderService.cart,
            builder: (context, lines, _) {
              if (lines.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 44,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add dishes from a canteen menu to order.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    FoodOrderService.cartRestaurant ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final line in lines) _CartRow(line: line),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          'Rs. ${FoodOrderService.cartTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _note,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Note for the kitchen (optional)',
                      hintText: 'No chilli, extra sambol...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _placing ? null : _placeOrder,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    child: Text(
                      _placing ? 'Placing order...' : 'Place order',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You pay at the counter when you collect. The app does '
                    'not take payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.food.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Rs. ${line.food.price.toStringAsFixed(0)} each',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove one',
          onPressed: () => FoodOrderService.removeOne(line.food),
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ),
        Text(
          '${line.quantity}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          tooltip: 'Add one',
          onPressed: () => FoodOrderService.add(
            line.food,
            restaurantName: FoodOrderService.cartRestaurant ?? '',
          ),
          icon: const Icon(Icons.add_circle_outline, size: 20),
        ),
        SizedBox(
          width: 70,
          child: Text(
            'Rs. ${line.total.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
