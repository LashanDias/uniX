import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/lost_found_service.dart';
import '../../widgets/app_back_button.dart';

class LostFoundCloudReports extends StatelessWidget {
  const LostFoundCloudReports({super.key, this.type, this.history = false});
  final String? type;
  final bool history;
  @override
  Widget build(BuildContext context) {
    if (LostFoundService.userId == null) {
      return const Text('Sign in to view live Lost & Found reports.');
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: history ? LostFoundService.history() : LostFoundService.active(),
      builder: (context, snapshot) {
        final posts = (snapshot.data ?? [])
            .where((p) => type == null || p['type'] == type)
            .toList();
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (history)
              const Row(
                children: [
                  AppBackButton(),
                  Text(
                    'My report history',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            if (snapshot.hasError)
              const Text(
                'Live reports are unavailable. Please check your connection or try again later.',
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator()
            else if (posts.isEmpty)
              Text(
                history
                    ? 'No resolved or deleted reports yet.'
                    : 'No active reports yet.',
              ),
            for (final post in posts)
              Card(
                child: ListTile(
                  leading: (post['images'] as List).isEmpty
                      ? const Icon(Icons.inventory_2_outlined)
                      : Image.memory(
                          base64Decode(
                            (post['images'] as List).first as String,
                          ),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                  title: Text(
                    '${post['type'] == 'found' ? 'Found' : 'Lost'}: ${post['title']}',
                  ),
                  subtitle: Text('${post['location']} • ${post['status']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CloudReportDetail(itemId: post['itemId'] as String),
                    ),
                  ),
                ),
              ),
          ],
        );
        return history
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: content,
              )
            : content;
      },
    );
  }
}

class CloudReportDetail extends StatefulWidget {
  const CloudReportDetail({super.key, required this.itemId});
  final String itemId;
  @override
  State<CloudReportDetail> createState() => _CloudReportDetailState();
}

class _CloudReportDetailState extends State<CloudReportDetail> {
  bool _busy = false;
  Future<void> _act(String action) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'delete'
              ? 'Remove this report?'
              : 'Mark this report resolved?',
        ),
        content: const Text(
          'This stops future follow-ups and removes the report from active listings. Its history is retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await LostFoundService.respond(widget.itemId, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'resolve'
                ? 'Great! This item has been marked as resolved.'
                : 'Report removed from active listings.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to update this report. Please refresh and retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lost & Found'),
      leading: const AppBackButton(),
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: LostFoundService.watch(widget.itemId),
      builder: (context, snapshot) {
        final post = snapshot.data?.data();
        if (snapshot.hasError) {
          return const Center(child: Text('This report is unavailable.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (post == null) {
          return const Center(child: Text('This report no longer exists.'));
        }
        final owner = post['userId'] == LostFoundService.userId;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final image in post['images'] as List)
                  Image.memory(
                    base64Decode(image as String),
                    width: 190,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              post['title'] as String,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(post['description'] as String),
            const SizedBox(height: 16),
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(post['location'] as String),
            const SizedBox(height: 16),
            Text('Status: ${post['status']}'),
            if (post['resolvedAt'] is Timestamp)
              Text(
                'Resolved: ${(post['resolvedAt'] as Timestamp).toDate().toLocal()}',
              ),
            if (owner && post['status'] == 'active') ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : () => _act('resolve'),
                child: Text(
                  post['type'] == 'found' ? 'Returned to owner' : 'I found it',
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => _act('delete'),
                child: const Text('Remove report'),
              ),
            ],
          ],
        );
      },
    ),
  );
}
