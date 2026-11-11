import 'package:flutter/material.dart';

/// A prominent, authentic vehicle number plate badge widget that highlights
/// the vehicle number consistently across tables, headers, and dialogs.
class VehiclePlateBadge extends StatelessWidget {
  final String vehicleNumber;
  final bool isLarge;

  const VehiclePlateBadge({
    super.key,
    required this.vehicleNumber,
    this.isLarge = false,
  });

  /// Factory constructor for backward compatibility with `licensePlate`.
  factory VehiclePlateBadge.fromPlate({
    Key? key,
    required String licensePlate,
    bool isLarge = false,
  }) {
    return VehiclePlateBadge(
      key: key,
      vehicleNumber: licensePlate,
      isLarge: isLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slate 50
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF94A3B8), // Slate 400
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLarge ? 5 : 4,
              vertical: isLarge ? 3 : 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A), // Navy Blue
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'VMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 10 : 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: isLarge ? 10 : 7),
          Text(
            vehicleNumber.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: isLarge ? 16 : 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: const Color(0xFF0F172A), // Slate 900
            ),
          ),
        ],
      ),
    );
  }
}
