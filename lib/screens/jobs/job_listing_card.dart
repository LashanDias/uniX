import 'package:flutter/material.dart';
import '../../models/app_models.dart';

class JobListingCard extends StatelessWidget {
  const JobListingCard({super.key, required this.job});
  final JobItem job;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(job.company),
          const SizedBox(height: 8),
          Text('${job.type} • ${job.location}'),
          if (job.requirements.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Requirements',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              job.requirements,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Vacancy details')),
                  body: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              job.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(job.company),
                            Text('${job.type} • ${job.location}'),
                            const SizedBox(height: 24),
                            const Text(
                              'Job description',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SelectableText(
                              job.description.isEmpty
                                  ? 'No description provided.'
                                  : job.description,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Requirements',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SelectableText(
                              job.requirements.isEmpty
                                  ? 'No requirements provided.'
                                  : job.requirements,
                            ),
                            if (job.contactEmail.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'How to apply',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('Send your CV and the job title to:'),
                              SelectableText(job.contactEmail),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('View requirements & apply'),
          ),
        ],
      ),
    ),
  );
}
