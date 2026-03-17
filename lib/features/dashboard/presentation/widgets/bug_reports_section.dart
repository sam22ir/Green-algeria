import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/auth_service.dart';

class DashboardBugReportsSection extends StatefulWidget {
  const DashboardBugReportsSection({super.key});

  @override
  State<DashboardBugReportsSection> createState() => _DashboardBugReportsSectionState();
}

class _DashboardBugReportsSectionState extends State<DashboardBugReportsSection> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reports = await SupabaseService().getBugReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _resolve(int id) async {
    final user = AuthService().firebaseUser;
    if (user == null) return;
    await SupabaseService().resolveBugReport(id, user.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingCount = _reports.where((r) => r['status'] != "resolved").length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
      color: colorScheme.surface,
      child: ExpansionTile(
        leading: Icon(Icons.bug_report_outlined, color: colorScheme.primary),
        title: Text(
          'bug_reports_count'.tr(args: [pendingCount.toString()]), 
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)
        ),
        children: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20), 
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          else if (_reports.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20), 
              child: Text(
                'no_bug_reports'.tr(),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                final user = report['users'] ?? {};
                final isResolved = report['status'] == 'resolved';

                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  color: isResolved 
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
                    : colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user['full_name'] ?? 'unspecified'.tr(), 
                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isResolved 
                                  ? colorScheme.primary.withValues(alpha: 0.1) 
                                  : colorScheme.error.withValues(alpha: 0.1), 
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isResolved ? colorScheme.primary : colorScheme.error, 
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                isResolved ? 'resolved'.tr() : 'open'.tr(), 
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: isResolved ? colorScheme.primary : colorScheme.error, 
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'problem_type'.tr()}: ${report['problem_type']}', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13, 
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report['description'] ?? '', 
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                        ),
                        if (report['screenshot_url'] != null) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _showImage(report['screenshot_url']),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(report['screenshot_url'], height: 100, width: 100, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM HH:mm').format(DateTime.parse(report['created_at'])), 
                              style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            if (!isResolved)
                              TextButton.icon(
                                onPressed: () => _resolve(report['id']),
                                style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: Text('mark_as_resolved'.tr()),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showImage(String url) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: Text('cancel'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
