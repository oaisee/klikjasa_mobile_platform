import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/common/widgets/service_card_adapter.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_cubit.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Cari layanan...',
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchCubit>().clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  context.read<SearchCubit>().searchServices(value);
                } else {
                  context.read<SearchCubit>().clearSearch();
                }
              },
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _buildSearchResults(state),
        );
      },
    );
  }

  Widget _buildSearchResults(SearchState state) {
    if (state is SearchInitial) {
      return const Center(
        child: Text('Cari layanan yang Anda butuhkan'),
      );
    } else if (state is SearchLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state is SearchError) {
      return Center(
        child: Text('Terjadi kesalahan: ${state.message}'),
      );
    } else if (state is SearchLoaded) {
      if (state.services.isEmpty) {
        return const Center(
          child: Text('Tidak ada layanan yang ditemukan'),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.services.length,
        itemBuilder: (context, index) {
          final service = state.services[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ServiceCardAdapter.fromServiceWithLocation(
              service: service,
              onTap: () {
                context.go('/home/service-detail', extra: service);
              },
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
