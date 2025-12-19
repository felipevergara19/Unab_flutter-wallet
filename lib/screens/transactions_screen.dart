import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';

class TransactionsScreen extends StatefulWidget {
  final int? userId;
  const TransactionsScreen({super.key, this.userId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'Todos';
  late Future<List<dynamic>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.userId != null) {
      _transactionsFuture = ApiService.getProducts(widget.userId!);
    } else {
      _transactionsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadData();
            });
            await _transactionsFuture;
          },
          child: Column(
            children: [
              const _TopAppBar(),
              _FilterChips(
                selectedFilter: _selectedFilter,
                onFilterSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _transactionsFuture,
                  builder: (context, snapshot) {
                    // Loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      // Error with retry button?
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Error al cargar datos',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: _loadData,
                              child: Text(
                                "Reintentar",
                                style: TextStyle(color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // Allow pull to refresh even on empty
                      return Stack(
                        children: [
                          ListView(), // Hidden list to allow pull
                          const Center(
                            child: Text(
                              'No hay transacciones',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    }

                    // Filter logic
                    final allTransactions = snapshot.data!;
                    final filteredTransactions = allTransactions.where((t) {
                      final type = t['type'] ?? 'expense';
                      if (_selectedFilter == 'Todos') return true;
                      if (_selectedFilter == 'Ingresos')
                        return type == 'income';
                      if (_selectedFilter == 'Gastos') return type == 'expense';
                      return true;
                    }).toList();

                    // Reverse for newest first
                    final reversedList = filteredTransactions.reversed.toList();

                    if (reversedList.isEmpty) {
                      return Stack(
                        children: [
                          ListView(), // list for refresh
                          const Center(
                            child: Text(
                              "No hay movimientos con este filtro",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: reversedList.length,
                      itemBuilder: (context, index) {
                        final item = reversedList[index];
                        final type = item['type'] ?? 'expense';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _TransactionItem(
                            icon: type == 'income'
                                ? Icons.attach_money
                                : Icons.shopping_bag,
                            title: item['name'] ?? 'Transacción',
                            subtitle: 'Reciente',
                            amount: type == 'income'
                                ? '+${CurrencyFormatter.format((item['price'] as num).toDouble())}'
                                : '-${CurrencyFormatter.format((item['price'] as num).toDouble())}',
                            amountColor: type == 'income'
                                ? Colors.green
                                : Colors.redAccent,
                            iconBgColor: AppTheme.surfaceDark,
                            iconColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Historial',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'Todos',
            isSelected: selectedFilter == 'Todos',
            onTap: () => onFilterSelected('Todos'),
          ),
          const SizedBox(width: 12),
          _Chip(
            label: 'Ingresos',
            isSelected: selectedFilter == 'Ingresos',
            onTap: () => onFilterSelected('Ingresos'),
          ),
          const SizedBox(width: 12),
          _Chip(
            label: 'Gastos',
            isSelected: selectedFilter == 'Gastos',
            onTap: () => onFilterSelected('Gastos'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFF374151),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final Color iconBgColor;
  final Color iconColor;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF242D47),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
