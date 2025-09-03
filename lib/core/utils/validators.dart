/// Utility class untuk validasi input dalam aplikasi
/// 
/// Berisi berbagai fungsi validasi yang umum digunakan
/// seperti email, password, nomor telepon, dll.
class Validators {
  /// Validasi email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  /// Validasi password
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    
    if (value.length < minLength) {
      return 'Password minimal $minLength karakter';
    }
    
    return null;
  }

  /// Validasi konfirmasi password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    
    if (value != password) {
      return 'Konfirmasi password tidak sama';
    }
    
    return null;
  }

  /// Validasi nomor telepon Indonesia
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon wajib diisi';
    }
    
    // Remove all non-digit characters
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    
    // Check if it starts with 08 or 628
    if (cleanNumber.startsWith('08')) {
      if (cleanNumber.length < 10 || cleanNumber.length > 13) {
        return 'Nomor telepon tidak valid';
      }
    } else if (cleanNumber.startsWith('628')) {
      if (cleanNumber.length < 12 || cleanNumber.length > 15) {
        return 'Nomor telepon tidak valid';
      }
    } else {
      return 'Nomor telepon harus dimulai dengan 08 atau +62';
    }
    
    return null;
  }

  /// Validasi nama (tidak boleh kosong dan minimal 2 karakter)
  static String? validateName(String? value, {String fieldName = 'Nama'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName minimal 2 karakter';
    }
    
    return null;
  }

  /// Validasi harga (harus berupa angka positif)
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harga wajib diisi';
    }
    
    final price = double.tryParse(value.replaceAll(',', ''));
    if (price == null) {
      return 'Harga harus berupa angka';
    }
    
    if (price <= 0) {
      return 'Harga harus lebih dari 0';
    }
    
    return null;
  }

  /// Validasi deskripsi (minimal 10 karakter)
  static String? validateDescription(String? value, {int minLength = 10}) {
    if (value == null || value.isEmpty) {
      return 'Deskripsi wajib diisi';
    }
    
    if (value.trim().length < minLength) {
      return 'Deskripsi minimal $minLength karakter';
    }
    
    return null;
  }

  /// Validasi field yang wajib diisi
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Format URL tidak valid';
    }
    
    return null;
  }

  /// Validasi NIK (16 digit)
  static String? validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK wajib diisi';
    }
    
    final cleanNIK = value.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNIK.length != 16) {
      return 'NIK harus 16 digit';
    }
    
    return null;
  }
}