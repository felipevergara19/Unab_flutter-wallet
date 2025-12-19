import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final int userId;
  final bool isIncome;

  const AddTransactionScreen({
    super.key,
    required this.userId,
    this.isIncome = false,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isIncome = false;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome;
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();

    if (name.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.addProduct(
        name,
        amount,
        _isIncome ? 'Ingreso agregado' : 'Gasto agregado', // description
        _isIncome ? 'income' : 'expense', // type
        widget.userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isIncome ? 'Ingreso agregado' : 'Gasto agregado'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to trigger refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isIncome ? 'Agregar Ingreso' : 'Agregar Gasto',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Toggle Type
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIncome = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isIncome
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: !_isIncome
                            ? null
                            : Border.all(color: Colors.grey),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Gasto',
                        style: TextStyle(
                          color: !_isIncome ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIncome = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isIncome ? Colors.green : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: _isIncome
                            ? null
                            : Border.all(color: Colors.grey),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ingreso',
                        style: TextStyle(
                          color: _isIncome ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Concepto',
              placeholder: 'Ej. Café, Sueldo',
              prefixIcon: Icons.description,
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Monto',
              placeholder: '0',
              prefixIcon: Icons.attach_money,
              controller: _amountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome
                      ? Colors.green
                      : AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isIncome ? 'Guardar Ingreso' : 'Guardar Gasto',
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
    );
  }
}
