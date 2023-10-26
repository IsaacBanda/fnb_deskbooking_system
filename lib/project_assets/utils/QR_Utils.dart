import 'package:qr_flutter/qr_flutter.dart';

import '../../exports/export.dart';

class QRCodeGenerator extends StatelessWidget {
  final int? bookingId;

  const QRCodeGenerator({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    String data = bookingId?.toString() ?? ' ';

    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: QrImageView(
              data: data,
              size: 150.0,
              version: QrVersions.auto,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        const CustomTextField(
          text:
              'This QR-Code has been automatically sent to your email address',
          color: AppColors.white,
          fontWeight: FontWeight.w500,
          size: 16,
        ),
      ],
    );
  }
}
