import 'package:flutter/material.dart';

void main() => runApp(const NuksaanlogApp());

/// Nuksaanlog — wastage/spoilage/breakage log valued at COGS, with a ranked
/// worst-offender view. Mirrors the Go journal service.
class NuksaanlogApp extends StatelessWidget {
  const NuksaanlogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nuksaanlog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF8E3E3E), useMaterial3: true),
        home: const HomePage(),
      );
}

class Loss {
  final String item, reason;
  final double qty, cogs;
  Loss(this.item, this.qty, this.cogs, this.reason);
  double get value => qty * cogs;
}

/// ranked returns items by total rupee loss, worst first.
List<MapEntry<String, double>> ranked(List<Loss> losses) {
  final agg = <String, double>{};
  for (final l in losses) {
    agg[l.item] = (agg[l.item] ?? 0) + l.value;
  }
  final list = agg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return list;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _losses = <Loss>[];
  final _item = TextEditingController();
  final _qty = TextEditingController();
  final _cogs = TextEditingController();
  String _reason = 'spoiled';

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _add() {
    if (_item.text.trim().isEmpty || _n(_qty) <= 0) return;
    setState(() {
      _losses.insert(0, Loss(_item.text.trim(), _n(_qty), _n(_cogs), _reason));
      _item.clear();
      _qty.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rank = ranked(_losses);
    final total = _losses.fold(0.0, (s, l) => s + l.value);
    String m(double v) => '₹${v.toStringAsFixed(2)}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuksaanlog · wastage'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(14),
          child: Text('Total lost ${m(total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _item, decoration: const InputDecoration(labelText: 'Item', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            SizedBox(width: 70, child: TextField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: TextField(controller: _cogs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '₹ cost', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            DropdownButton<String>(
              value: _reason,
              items: const [
                DropdownMenuItem(value: 'spoiled', child: Text('spoiled')),
                DropdownMenuItem(value: 'broken', child: Text('broken')),
                DropdownMenuItem(value: 'expired', child: Text('expired')),
              ],
              onChanged: (v) => setState(() => _reason = v ?? 'spoiled'),
            ),
            const Spacer(),
            FilledButton(onPressed: _add, child: const Text('Log loss')),
          ]),
        ])),
        if (rank.isNotEmpty) ...[
          const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Worst offenders', style: TextStyle(fontWeight: FontWeight.w600)))),
          for (var i = 0; i < rank.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
              title: Text(rank[i].key),
              trailing: Text(m(rank[i].value), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ]),
    );
  }
}
