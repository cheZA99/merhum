import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/obituary_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/obituary_card_widget.dart';
import '../../widgets/loading_widget.dart';
import 'obituary_detail_screen.dart';

class ObituarySearchScreen extends StatefulWidget {
  final String? initialQuery;
  const ObituarySearchScreen({super.key, this.initialQuery});

  @override
  State<ObituarySearchScreen> createState() => _ObituarySearchScreenState();
}

class _ObituarySearchScreenState extends State<ObituarySearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchCtrl.text = widget.initialQuery!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _doSearch(q));
  }

  void _doSearch(String q) {
    if (q.trim().isEmpty) {
      context.read<ObituaryProvider>().search(null);
    } else {
      context.read<ObituaryProvider>().search(q.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Unesite ime ili prezime...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Consumer<ObituaryProvider>(
        builder: (context, p, _) {
          if (p.isLoading) return const LoadingWidget();

          if (p.results.isEmpty) {
            final query = _searchCtrl.text.trim();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty ? 'Trenutno nema smrtovnica.' : 'Nema rezultata za "$query"',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => p.search(_searchCtrl.text.trim()),
            child: ListView.builder(
              itemCount: p.results.length,
              itemBuilder: (_, i) => ObituaryCardWidget(
                obituary: p.results[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ObituaryDetailScreen(slug: p.results[i].uniqueSlug)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
