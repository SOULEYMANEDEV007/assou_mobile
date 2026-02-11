// Test script to verify deep link handling
// Run with: dart test_deep_link.dart

import 'dart:io';

void main() {
  print('🔗 Deep Link Configuration Test\n');

  print('Expected Deep Link URLs:');
  print('✅ Success: assou://payment/success?ref=PAI-68b32952a5140');
  print('❌ Error: assou://payment/error?ref=PAI-68b32952a5140');
  //print();

  print('Testing Android Intent (simulate):');
  const successIntent =
      'am start -W -a android.intent.action.VIEW -d "assou://payment/success?ref=TEST123"';
  const errorIntent =
      'am start -W -a android.intent.action.VIEW -d "assou://payment/error?ref=TEST123"';

  print('Success command: adb shell $successIntent');
  print('Error command: adb shell $errorIntent');
  //print();

  print('📋 Backend Configuration Needed:');
  print('When creating Wave checkout, provide these redirect URLs:');
  print('- success_url: "assou://payment/success?ref={PAYMENT_REFERENCE}"');
  print('- error_url: "assou://payment/error?ref={PAYMENT_REFERENCE}"');
  //print();

  print('🔧 Wave API Integration:');
  print('Make sure your backend sends these URLs when creating Wave checkout:');
  print('''
curl -X POST "https://api.wave.com/v1/checkout/sessions" \\
  -H "Authorization: Bearer WAVE_API_KEY" \\
  -d '{
    "amount": 5,
    "currency": "XOF",
    "success_url": "assou://payment/success?ref=PAI-68b32952a5140",
    "error_url": "assou://payment/error?ref=PAI-68b32952a5140"
  }'
  ''');
}
