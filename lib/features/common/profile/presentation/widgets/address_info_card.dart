import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';

class AddressInfoCard extends StatelessWidget {
  final String? detailJalan;
  final String? desaKelurahan;
  final String? kecamatan;
  final String? kabupatenKota;
  final String? provinsi;
  final String? kodePos;
  final String? phoneNumber;
  final VoidCallback onEditProfilePressed;

  const AddressInfoCard({
    super.key,
    this.detailJalan,
    this.desaKelurahan,
    this.kecamatan,
    this.kabupatenKota,
    this.provinsi,
    this.kodePos,
    this.phoneNumber,
    required this.onEditProfilePressed,
  });

  Widget _buildAddressText(String? text, {bool isBold = false, double fontSize = 14.0}) {
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.textSecondary,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          height: 1.4,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
  
  Widget _buildAddressRow(String? part1, String? part2, {String separator = ', '}) {
    List<String> parts = [];
    if (part1 != null && part1.isNotEmpty) parts.add(part1);
    if (part2 != null && part2.isNotEmpty) parts.add(part2);
    
    if (parts.isEmpty) return const SizedBox.shrink();
    return _buildAddressText(parts.join(separator));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> addressWidgets = [];

    if (detailJalan != null && detailJalan!.isNotEmpty) {
      addressWidgets.add(_buildAddressText(detailJalan, isBold: true, fontSize: 15.0));
    }
    
    addressWidgets.add(_buildAddressRow(desaKelurahan, kecamatan));
    addressWidgets.add(_buildAddressRow(kabupatenKota, provinsi));

    if (kodePos != null && kodePos!.isNotEmpty) {
      // Cek apakah kodePos sudah ada di akhir provinsi atau kabupatenKota
      // Ini untuk menghindari duplikasi jika formatnya sudah "Kota, Provinsi KodePos"
      bool kodePosAlreadyShown = false;
      if (provinsi != null && provinsi!.contains(kodePos!)) kodePosAlreadyShown = true;
      if (kabupatenKota != null && kabupatenKota!.contains(kodePos!)) kodePosAlreadyShown = true;
      
      if (!kodePosAlreadyShown) {
        addressWidgets.add(_buildAddressText('Kode Pos: $kodePos'));
      }
    }

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      addressWidgets.add(const SizedBox(height: 6.0)); // Sedikit spasi sebelum nomor HP
      addressWidgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Agar ikon sejajar dengan baris pertama teks jika nomor HP panjang
          children: [
            const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8.0),
            Expanded(child: _buildAddressText(phoneNumber)),
          ],
        )
      );
    }
    
    bool hasAnyAddressInfo = detailJalan != null && detailJalan!.isNotEmpty ||
                             desaKelurahan != null && desaKelurahan!.isNotEmpty ||
                             kecamatan != null && kecamatan!.isNotEmpty ||
                             kabupatenKota != null && kabupatenKota!.isNotEmpty ||
                             provinsi != null && provinsi!.isNotEmpty ||
                             (kodePos != null && kodePos!.isNotEmpty) || // Perlu dicek ulang logikanya jika kodePos sudah include
                             phoneNumber != null && phoneNumber!.isNotEmpty;


    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.alamat,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  label: const Text(
                    AppStrings.ubah,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onEditProfilePressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            if (hasAnyAddressInfo)
              ...addressWidgets
            else
              Text(
                AppStrings.belumAdaAlamat,
                style: TextStyle(
                  fontSize: 14.0,
                  color: AppColors.textSecondary.withAlpha((0.7 * 255).round()),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}