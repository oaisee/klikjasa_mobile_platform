part of 'provider_summary_bloc.dart';

@immutable
abstract class ProviderSummaryEvent extends Equatable {
  const ProviderSummaryEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToProviderSummary extends ProviderSummaryEvent {
  final String providerId;

  const SubscribeToProviderSummary({required this.providerId});

  @override
  List<Object> get props => [providerId];
}

class RefreshProviderSummary extends ProviderSummaryEvent {
  final String? providerId;
  final Completer<void>? completer;

  const RefreshProviderSummary({this.providerId, this.completer});

  @override
  List<Object?> get props => [providerId, completer];
}

// Internal events

class _ProviderSummaryUpdated extends ProviderSummaryEvent {
  final ProviderSummaryDataEntity summaryData;
  final String providerId;

  const _ProviderSummaryUpdated(this.summaryData, {required this.providerId});

  @override
  List<Object> get props => [summaryData, providerId];
}

class _ProviderSummaryFailed extends ProviderSummaryEvent {
  final String message;
  final String? providerId;

  const _ProviderSummaryFailed(this.message, {this.providerId});

  @override
  List<Object?> get props => [message, providerId];
}