import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OfferData {
  static const Map<String, String> offers = {
    'المكثفات': 'Description for Report 1',
    'الخلايا الاحطياتية بالمحطات': 'Description for Report 2',
    'نسب التحميل للمحولات': 'Description for Report 3',
    // Add more as needed
  };

  Future<List<Report>> fetchReports() async {
    await Future.delayed(const Duration(seconds: 1));
    return offers.entries
        .map(
          (e) => Report(
            name: e.key,
            description: e.value,
            date: DateTime.now().toString().substring(0, 10),
          ),
        )
        .toList();
  }
}

// Card widget for displaying a report
class OfferCard extends StatelessWidget {
  final Report report;
  final int index;

  const OfferCard({super.key, required this.report, required this.index});

  @override
  Widget build(BuildContext context) {
    final gradient = [
      Colors.blueAccent,
      Colors.lightBlueAccent, // Simplified gradient colors
    ];

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padding,
        vertical: AppConstants.spacing,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.blue, width: 1),
        ),
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Row(
          children: [
            const SizedBox(width: AppConstants.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: Appfontstring.ChangaLight,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacing),
                  Text(
                    report.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.brown),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.spacing),
                  Text(
                    report.date,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
              child: const Icon(Icons.read_more, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// Main screen for displaying reports
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offerData = OfferData();

    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Appcolors.primaryColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'تـقارير فنية و هندسية',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 212, 237, 24),
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.Almarai_Bold,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacing),
            const Divider(thickness: 2, indent: 50, endIndent: 50),
            const SizedBox(height: AppConstants.padding),
            Expanded(
              child: FutureBuilder<List<Report>>(
                future: offerData.fetchReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListView.builder(
                        itemCount: 6,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          height: 100,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load reports'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No reports available'));
                  }

                  final reports = snapshot.data!;
                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) =>
                        OfferCard(report: reports[index], index: index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
