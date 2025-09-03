part of 'provider_summary_bloc.dart';

@immutable
abstract class ProviderSummaryState extends Equatable {
  final String? providerId;

  const ProviderSummaryState({this.providerId});

  @override
  List<Object?> get props => [providerId];
}

class ProviderSummaryInitial extends ProviderSummaryState {
  const ProviderSummaryInitial() : super(providerId: null);
}

class ProviderSummaryLoading extends ProviderSummaryState {
  const ProviderSummaryLoading({super.providerId});
}

class ProviderSummaryLoaded extends ProviderSummaryState {
  final ProviderSummaryDataEntity summaryData;

  const ProviderSummaryLoaded({
    required this.summaryData,
    required String providerId,
  }) : super(providerId: providerId);

  @override
  List<Object?> get props => [summaryData, providerId];
}

class ProviderSummaryError extends ProviderSummaryState {
  final String message;

  const ProviderSummaryError({required this.message, super.providerId});

  @override
  List<Object?> get props => [message, providerId];
}
