import 'package:flutter/material.dart';

/// Global wiederverwendbarer Loading-Indicator, u. a. verwendet, während
/// das `app`-Feature die Verbindung zu Supabase aufbaut.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
