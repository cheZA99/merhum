import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/sidebar_widget.dart';
import 'user_form_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchCtrl = TextEditingController();
  String? _filterRole;
  bool? _filterIsLocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 12,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Korisnici', style: AppTextStyles.heading1),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _openForm,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Dodaj korisnika'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Ime ili korisničko ime',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (v) {
              final p = context.read<UserProvider>();
              p.filterName = v.trim().isEmpty ? null : v.trim();
              p.currentPage = 1;
              p.loadAll();
            },
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            value: _filterRole,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Uloga',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Sve uloge')),
              DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
              DropdownMenuItem(value: 'Porodica', child: Text('Porodica')),
              DropdownMenuItem(value: 'JavniKorisnik', child: Text('Javni korisnik')),
              DropdownMenuItem(value: 'Imam', child: Text('Imam')),
              DropdownMenuItem(value: 'PogrebnoPreduzeće', child: Text('Pogrebno preduzeće')),
            ],
            onChanged: (v) {
              setState(() => _filterRole = v);
              final p = context.read<UserProvider>();
              p.filterRole = v;
              p.currentPage = 1;
              p.loadAll();
            },
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<bool?>(
            value: _filterIsLocked,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Svi')),
              DropdownMenuItem(value: false, child: Text('Aktivni')),
              DropdownMenuItem(value: true, child: Text('Blokirani')),
            ],
            onChanged: (v) {
              setState(() => _filterIsLocked = v);
              final p = context.read<UserProvider>();
              p.filterIsLocked = v;
              p.currentPage = 1;
              p.loadAll();
            },
          ),
        ),
        OutlinedButton(
          onPressed: _resetFilters,
          child: const Text('Resetuj filtere'),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filterRole = null;
      _filterIsLocked = null;
      _searchCtrl.clear();
    });
    context.read<UserProvider>().resetFilters();
  }

  Widget _buildBody() {
    return Consumer<UserProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.errorMessage!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: p.loadAll, child: const Text('Pokušaj ponovo')),
              ],
            ),
          );
        }
        if (p.users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.manage_accounts, size: 64, color: AppColors.textLight),
                SizedBox(height: 16),
                Text('Nema korisnika', style: AppTextStyles.body),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(child: _buildTable(p)),
            _buildSummary(p),
            _buildPagination(p),
          ],
        );
      },
    );
  }

  Widget _buildTable(UserProvider p) {
    return Card(
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1.8),
            4: FlexColumnWidth(1.2),
            5: FixedColumnWidth(80),
            6: FlexColumnWidth(1.2),
            7: FixedColumnWidth(110),
          },
          children: [
            _tableHeader(),
            ...p.users.map(_tableRow),
          ],
        ),
      ),
    );
  }

  TableRow _tableHeader() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [
        _headerCell('Korisničko ime', style),
        _headerCell('Ime i prezime', style),
        _headerCell('Email', style),
        _headerCell('Uloga', style),
        _headerCell('Grad', style),
        _headerCell('Potvrđen', style),
        _headerCell('Status', style),
        _headerCell('Akcije', style),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: style),
    );
  }

  TableRow _tableRow(UserModel u) {
    final currentUsername = context.read<AuthProvider>().username;
    final isSelf = u.username == currentUsername;

    return TableRow(
      children: [
        _cell(u.username),
        _cell(u.fullName),
        _cell(u.email),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _roleChip(u.role),
        ),
        _cell(u.cityName ?? '-',
            style: u.cityName == null
                ? const TextStyle(color: AppColors.textLight, fontSize: 13)
                : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Icon(
            u.isConfirmed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: u.isConfirmed ? Colors.green : AppColors.textLight,
            size: 18,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _statusChip(u.isLocked),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Uredi',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _openForm(user: u),
              ),
              IconButton(
                icon: Icon(
                  u.isLocked ? Icons.lock_open : Icons.lock,
                  size: 18,
                  color: u.isLocked ? Colors.green : Colors.orange,
                ),
                tooltip: u.isLocked ? 'Odblokiraj' : 'Blokiraj',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: isSelf ? null : () => _confirmToggleLock(u),
              ),
              IconButton(
                icon: const Icon(Icons.password, size: 18, color: AppColors.textLight),
                tooltip: 'Resetuj lozinku',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _confirmResetPassword(u),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text, style: style ?? AppTextStyles.body),
    );
  }

  Widget _roleChip(String role) {
    Color color;
    String label;
    switch (role) {
      case 'Administrator':
        color = const Color(0xFF1B5E20);
        label = 'Administrator';
        break;
      case 'Porodica':
        color = Colors.blue.shade700;
        label = 'Porodica';
        break;
      case 'JavniKorisnik':
        color = Colors.grey.shade600;
        label = 'Javni korisnik';
        break;
      case 'Imam':
        color = Colors.orange.shade700;
        label = 'Imam';
        break;
      case 'PogrebnoPreduzeće':
        color = Colors.purple.shade700;
        label = 'Pogrebno preduzeće';
        break;
      default:
        color = Colors.grey;
        label = role;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statusChip(bool isLocked) {
    final color = isLocked ? AppColors.error : Colors.green;
    final label = isLocked ? 'Blokiran' : 'Aktivan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummary(UserProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        'Ukupno korisnika: ${p.totalCount}',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPagination(UserProvider p) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: p.currentPage > 1 ? p.previousPage : null,
          ),
          Text('Stranica ${p.currentPage} od ${p.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: p.currentPage < p.totalPages ? p.nextPage : null,
          ),
        ],
      ),
    );
  }

  void _openForm({UserModel? user}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<UserProvider>(),
          child: UserFormScreen(user: user),
        ),
      ),
    );
  }

  void _confirmToggleLock(UserModel u) {
    final action = u.isLocked ? 'Odblokiraj' : 'Blokiraj';
    final question = u.isLocked
        ? 'Odblokirati korisnika "${u.username}"?'
        : 'Blokirati korisnika "${u.username}"?';

    ConfirmationDialog.show(
      context,
      title: '$action korisnika',
      content: question,
      onConfirm: () async {
        final ok = await context.read<UserProvider>().toggleLock(u.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(u.isLocked
                  ? 'Korisnik "${u.username}" je odblokiran.'
                  : 'Korisnik "${u.username}" je blokiran.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _confirmResetPassword(UserModel u) {
    ConfirmationDialog.show(
      context,
      title: 'Resetovanje lozinke',
      content:
          'Resetovati lozinku za "${u.username}" na "test"?\n\nUpozorenje: korisnik mora promijeniti lozinku pri prvoj prijavi.',
      onConfirm: () async {
        final ok = await context.read<UserProvider>().resetPassword(u.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lozinka za "${u.username}" je resetovana na "test".'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }
}
