import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  final int? userId;
  final String? userName;

  const HomeScreen({super.key, this.userId, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.userId != null) {
      _productsFuture = ApiService.getProducts(widget.userId!);
    } else {
      _productsFuture = Future.value([]);
    }
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            await _productsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: FutureBuilder<List<dynamic>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                // Default values while loading or if error
                List<dynamic> products = [];
                double totalBalance = 0.0;
                double totalIncome = 0.0;
                double totalExpense = 0.0;

                if (snapshot.hasData) {
                  products = snapshot.data!;

                  for (var item in products) {
                    final price = (item['price'] is int)
                        ? (item['price'] as int).toDouble()
                        : (item['price'] as double);

                    if (item['type'] == 'income') {
                      totalIncome += price;
                    } else {
                      totalExpense += price;
                    }
                  }
                  totalBalance = totalIncome - totalExpense;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopAppBar(userName: widget.userName),
                    const SizedBox(height: 16),
                    _BalanceCard(balance: totalBalance),
                    const SizedBox(height: 16),
                    _ActionButtons(
                      userId: widget.userId,
                      onTransactionAdded: _refreshData,
                    ),
                    const SizedBox(height: 16),
                    _SpendingChartCard(totalSpent: totalExpense),
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      title: 'Actividad Reciente',
                      actionText: 'Ver Todo',
                    ),
                    const SizedBox(height: 12),
                    // Only show loading indicator for the list part if specifically waiting?
                    // Or just show data/empty.
                    // Since we hoist fetching, we have data or waiting here.
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (snapshot.hasError)
                      Center(
                        child: Text(
                          'Error al cargar datos',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      )
                    else
                      _RecentTransactionsList(transactions: products),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  final String? userName;
  const _TopAppBar({this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBv1vT9sb78VY6d2bavkeNWXZOoiLaTZsW92aAeGQJ-ogVlhf5ywGZkuPCBKSIb8BCQQONvrjOLoy_1JkvS4mYrZXdl_ukureU7HiHtRU7h3uF8mZsxDw-z1Au3l1juW4u8V_5JMAhj6KqW-_u952FLkbv2pQwmbty_wuEYpA2GZ0sIgXB1KQiy1B87zvSSchDHJAWNgxnDtKpMaJ3mCTsPWePp2yBPZkC3KpEb5wcaQlhiMXGmSPgTTAXwTj59SNwZ27bZla9iCSuh',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Hola, ${userName ?? "Usuario"}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Total',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(balance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.visibility_off,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final int? userId;
  final VoidCallback? onTransactionAdded;

  const _ActionButtons({this.userId, this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(userId: userId!),
                  ),
                ).then((value) {
                  // If true, data was added
                  if (value == true) {
                    onTransactionAdded?.call();
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: No User ID')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Gasto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTransactionScreen(userId: userId!, isIncome: true),
                  ),
                ).then((value) {
                  if (value == true) {
                    onTransactionAdded?.call();
                  }
                });
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Ingreso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF242D47),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpendingChartCard extends StatelessWidget {
  final double totalSpent;
  const _SpendingChartCard({required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    // For visualization, let's assume a dummy budget
    const double budget = 1000.0;
    final double percentage = (totalSpent / budget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastos del Mes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Ver Detalles',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Simplified Circular Chart Visualization
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percentage,
                      backgroundColor: const Color(0xFF242D47),
                      color: AppTheme.primaryColor,
                      strokeWidth: 12,
                    ),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(totalSpent),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'de tu presupuesto de ${CurrencyFormatter.format(budget)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          actionText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final List<dynamic> transactions;

  const _RecentTransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay movimientos recientes',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: transactions.map((product) {
        final type = product['type'] ?? 'expense';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _TransactionItem(
            icon: type == 'income' ? Icons.attach_money : Icons.shopping_bag,
            title: product['name'] ?? 'Producto',
            date: 'Hoy',
            amount: type == 'income'
                ? '+${CurrencyFormatter.format((product['price'] as num).toDouble())}'
                : '-${CurrencyFormatter.format((product['price'] as num).toDouble())}',
            amountColor: type == 'income' ? Colors.green : Colors.redAccent,
          ),
        );
      }).toList(),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final Color amountColor;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF242D47),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
