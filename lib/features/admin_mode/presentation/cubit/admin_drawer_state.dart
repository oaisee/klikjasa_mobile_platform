/// State untuk mengelola drawer pada halaman admin
abstract class AdminDrawerState {
  const AdminDrawerState();
}

/// State saat drawer tertutup
class AdminDrawerClosed extends AdminDrawerState {
  const AdminDrawerClosed();
}

/// State saat drawer terbuka
class AdminDrawerOpened extends AdminDrawerState {
  const AdminDrawerOpened();
}
