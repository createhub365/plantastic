import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../navigation/plantastic_navigation.dart';

/// In-memory search over shop-visible products (title + subtitle).
class PlantSearchDelegate extends SearchDelegate<void> {
  PlantSearchDelegate(this.products);

  final List<Product> products;

  @override
  String get searchFieldLabel => 'Search seeds';

  List<Product> _matches(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return products.where((p) {
      final t = p.title.toLowerCase();
      final s = p.subtitle.toLowerCase();
      return t.contains(needle) || s.contains(needle);
    }).toList(growable: false);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear',
          onPressed: () {
            HapticFeedback.lightImpact();
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () {
        HapticFeedback.lightImpact();
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _ResultsBody(
        delegate: this,
        matches: _matches(query),
      );

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Type a seed or plant name',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return _ResultsBody(delegate: this, matches: _matches(q));
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.delegate,
    required this.matches,
  });

  final PlantSearchDelegate delegate;
  final List<Product> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No matches for "${delegate.query}"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final p = matches[i];
        return ListTile(
          title: Text(p.title),
          subtitle: Text(
            p.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            final nav = Navigator.of(context);
            delegate.close(context, null);
            nav.push<void>(plantasticProductDetailRoute(p.id));
          },
        );
      },
    );
  }
}
