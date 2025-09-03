
/// Utilitas untuk memfilter konten pesan agar tidak mengandung informasi kontak pribadi
class ContentFilter {
  /// Memfilter teks untuk menghapus nomor kontak (HP, WA, dll)
  static String filterContactInfo(String text) {
    if (text.isEmpty) return text;

    // Filter nomor telepon dengan berbagai format
    // Format: +62812345678, 0812-3456-789, 08123456789, dll.
    final phoneRegex = RegExp(
      r'(\+62|62|0)8[1-9][0-9]{6,10}|(\+62|62|0)[0-9]{2,3}[- ]?[0-9]{6,10}',
    );
    
    // Filter kata-kata yang mengindikasikan nomor kontak
    final contactKeywords = [
      'nomor hp', 'no hp', 'nomor wa', 'no wa', 'nomor whatsapp', 
      'no whatsapp', 'nomor telepon', 'no telepon', 'no telp', 
      'nomor handphone', 'kontak saya', 'hubungi saya di'
    ];

    String filteredText = text;

    // Ganti nomor telepon dengan teks [nomor dihapus]
    filteredText = filteredText.replaceAllMapped(
      phoneRegex, 
      (match) => '[nomor dihapus]'
    );

    // Cek dan filter frasa yang mengandung kata kunci kontak
    for (final keyword in contactKeywords) {
      if (filteredText.toLowerCase().contains(keyword)) {
        // Cari indeks kata kunci
        final keywordIndex = filteredText.toLowerCase().indexOf(keyword);
        
        // Ambil substring sebelum kata kunci
        final beforeKeyword = filteredText.substring(0, keywordIndex);
        
        // Cari indeks spasi atau titik setelah kata kunci
        int endIndex = filteredText.indexOf(' ', keywordIndex + keyword.length + 1);
        if (endIndex == -1) {
          endIndex = filteredText.indexOf('.', keywordIndex + keyword.length + 1);
        }
        if (endIndex == -1) {
          endIndex = filteredText.length;
        }
        
        // Ambil substring setelah frasa yang mengandung kontak
        final afterPhrase = endIndex < filteredText.length 
            ? filteredText.substring(endIndex)
            : '';
        
        // Gabungkan kembali dengan teks pengganti
        filteredText = '$beforeKeyword[informasi kontak dihapus]$afterPhrase';
      }
    }

    return filteredText;
  }

  /// Memvalidasi teks input agar tidak mengandung informasi kontak
  static bool containsContactInfo(String text) {
    if (text.isEmpty) return false;

    // Regex untuk mendeteksi nomor telepon
    final phoneRegex = RegExp(
      r'(\+62|62|0)8[1-9][0-9]{6,10}|(\+62|62|0)[0-9]{2,3}[- ]?[0-9]{6,10}',
    );
    
    // Kata kunci yang mengindikasikan informasi kontak
    final contactKeywords = [
      'nomor hp', 'no hp', 'nomor wa', 'no wa', 'nomor whatsapp', 
      'no whatsapp', 'nomor telepon', 'no telepon', 'no telp', 
      'nomor handphone', 'kontak saya', 'hubungi saya di'
    ];

    // Cek apakah teks mengandung nomor telepon
    if (phoneRegex.hasMatch(text)) {
      return true;
    }

    // Cek apakah teks mengandung kata kunci kontak
    for (final keyword in contactKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Memfilter pesan sebelum dikirim
  static Map<String, dynamic> validateOutgoingMessage(String text) {
    final containsContact = containsContactInfo(text);
    
    if (containsContact) {
      return {
        'isValid': false,
        'message': 'Pesan tidak dapat dikirim karena mengandung informasi kontak pribadi. '
            'Untuk keamanan, gunakan fitur chat dalam aplikasi untuk berkomunikasi.',
      };
    }
    
    return {
      'isValid': true,
      'message': text,
    };
  }
}
