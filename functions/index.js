const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')('Replace this key'); // Replace with your real Stripe secret key

admin.initializeApp();

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  console.log('✅ Data received from Flutter:', data);

  const amount = Number(data?.data?.amount ?? 0); // ✅ notice the double `.data.amount`

  if (isNaN(amount) || amount <= 0) {
    console.error('❌ Invalid amount:', amount);
    throw new functions.https.HttpsError('invalid-argument', 'Amount must be a valid number.');
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency: 'myr',
      payment_method_types: ['card'],
    });

    console.log('✅ PaymentIntent created:', paymentIntent.id);

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (err) {
    console.error('❌ Stripe error:', err);
    throw new functions.https.HttpsError('internal', err.message);
  }
});


