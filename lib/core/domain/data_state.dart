import 'package:equatable/equatable.dart';

abstract class DataState<T> extends Equatable {
  final T? data;
  final String? error;

  const DataState({this.data, this.error});

  @override
  List<Object?> get props => [data, error];
}

class DataSuccess<T> extends DataState<T> {
  // Pastikan untuk memanggil super dengan data yang sebenarnya.
  // DataSuccess hanya memiliki 'data', jadi kita hanya perlu 'data' di props.
  const DataSuccess(T dataValue) : super(data: dataValue);

  // Ambil data dari superclass untuk props
  T get dataValue => super.data!;

  @override
  List<Object?> get props => [data]; // data dari superclass
}

class DataFailed<T> extends DataState<T> {
  // DataFailed hanya memiliki 'error', jadi kita hanya perlu 'error' di props.
  const DataFailed(String errorValue) : super(error: errorValue);

  // Ambil error dari superclass untuk props
  String get errorValue => super.error!;

  @override
  List<Object?> get props => [error]; // error dari superclass
}