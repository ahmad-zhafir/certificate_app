import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  bool _processing = false;
  final TextEditingController _customAmountController = TextEditingController();

  Future<void> _makeDonation(int amountInCents) async {
    setState(() => _processing = true);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('createPaymentIntent')
          .call({'amount': amountInCents});
      final clientSecret = result.data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CertiSafe Donation',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      _customAmountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Thank you for your donation!')),
      );
    } on StripeException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Payment canceled or failed')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Something went wrong')),
      );
    }
    setState(() => _processing = false);
  }

  void _handleCustomDonation() {
    final amount = int.tryParse(_customAmountController.text.trim());
    if (amount != null && amount > 0) {
      _makeDonation(amount * 100); // Convert RM to cents
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enter a valid amount')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Donate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Square banner with icon
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 80,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main heading
                Text(
                  'Support Our Mission 💖',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtext
                Text(
                  'Help us keep CertiSafe running and improving. Your donation makes a difference!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(height: 30),

                // Preset amount buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var amount in [5, 10, 20])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: _processing ? null : () => _makeDonation(amount * 100),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("RM$amount"),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Custom input
                TextFormField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.attach_money),
                    prefixText: "RM ",
                    labelText: "Custom Amount",
                    labelStyle: TextStyle(color: Colors.blueGrey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Donate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processing ? null : _handleCustomDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _processing
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "DONATE CUSTOM AMOUNT",
                      style: TextStyle(letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  '💡 All donations are anonymous. We do not collect any personal or payment details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
