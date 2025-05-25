import 'dart:typed_data';

class Friend {
  final String name;
  final String email;
  final double amountOwed;
  final bool owesYou;
  final Uint8List? imageUrl; // For storing contact photo bytes

  Friend({
    required this.name,
    required this.email,
    required this.amountOwed,
    required this.owesYou,
    required this.imageUrl,
  });
}