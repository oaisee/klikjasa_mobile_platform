// File stub untuk platform web
// Menyediakan implementasi File yang kompatibel dengan web

import 'dart:typed_data';

class File {
  final String path;
  
  File(this.path);
  
  // Stub method untuk readAsBytes
  Future<Uint8List> readAsBytes() async {
    return Uint8List(0);
  }
  
  // Stub method untuk writeAsBytes
  Future<File> writeAsBytes(List<int> bytes) async {
    return this;
  }
  
  // Stub method untuk exists
  Future<bool> exists() async {
    return false;
  }
  
  // Stub method untuk length
  Future<int> length() async {
    return 0;
  }
  
  // Stub method untuk delete
  Future<void> delete() async {}
}
