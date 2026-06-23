import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/cemetery_prediction_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/prediction_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  static final _dateFormat = DateFormat('dd.MM.yyyy.');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionProvider>().loadAll();
    });
  }

  Future<void> _train() async {
    final provider = context.read<PredictionProvider>();
    final success = await provider.trainModel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Model je uspješno treniran.'
            : provider.errorMessage ?? 'Greška pri treniranju modela.'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 13,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(
            child: Consumer<PredictionProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    const Divider(height: 1),
                    Expanded(child: _buildBody(provider)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PredictionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Predviđanje popunjenosti groblja',
                  style: AppTextStyles.heading1,
                ),
              ),
              ElevatedButton.icon(
                onPressed: provider.isTraining ? null : _train,
                icon: provider.isTraining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.model_training, size: 18),
                label: Text(provider.isTraining ? 'Treniram...' : 'Treniraj model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Model strojnog učenja procjenjuje za koliko mjeseci će svako groblje '
            'biti popunjeno. Procjena se temelji na trenutnoj popunjenosti i '
            'prosječnom broju ukopa po mjesecu iz historijskih podataka.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PredictionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.predictions.isEmpty) {
      return _buildMessage(
        icon: Icons.error_outline,
        text: provider.errorMessage!,
        color: AppColors.error,
      );
    }

    if (provider.predictions.isEmpty) {
      return _buildMessage(
        icon: Icons.insights_outlined,
        text: 'Nema dostupnih predviđanja. Pokrenite treniranje modela.',
        color: AppColors.textLight,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: provider.predictions.length,
      itemBuilder: (context, index) =>
          _PredictionCard(prediction: provider.predictions[index], dateFormat: _dateFormat),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(text, style: AppTextStyles.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final CemeteryPredictionModel prediction;
  final DateFormat dateFormat;

  const _PredictionCard({required this.prediction, required this.dateFormat});

  bool get _isAlmostFull => prediction.predictedMonthsUntilFull < 6;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.landscape, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(prediction.cemeteryName, style: AppTextStyles.heading2),
                ),
                _ConfidenceBadge(level: prediction.confidenceLevel),
              ],
            ),
            const SizedBox(height: 16),
            _buildCurrentState(),
            const SizedBox(height: 16),
            _buildPredictionBox(),
            if (_isAlmostFull) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Preporučuje se planiranje proširenja',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    final percentage = prediction.occupancyPercentage.clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _stateChip('Kapacitet', '${prediction.totalCapacity}'),
            const SizedBox(width: 12),
            _stateChip('Zauzeto', '${prediction.currentOccupancy}'),
            const SizedBox(width: 12),
            _stateChip('Popunjenost', '${percentage.round()}%'),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 85 ? AppColors.error : AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stateChip(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildPredictionBox() {
    final months = prediction.predictedMonthsUntilFull.toStringAsFixed(1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Procjena: još $months mjeseci do popunjenja',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Očekivani datum popunjenja: ${dateFormat.format(prediction.estimatedFullDate)}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 2),
          Text(
            'Prosječno ukopa mjesečno: ${prediction.averageBurialsPerMonth.toStringAsFixed(1)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String level;
  const _ConfidenceBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (level) {
      'Visoka' => (AppColors.success, 'Visoka pouzdanost'),
      'Srednja' => (Colors.orange, 'Srednja pouzdanost'),
      _ => (Colors.grey, 'Niska pouzdanost'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
