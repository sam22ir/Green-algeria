import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_colors.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.client
          .from('upgrade_requests')
          .select('*, users(full_name, email)')
          .eq('status', 'pending');
      setState(() {
        _requests = res as List<dynamic>;
      });
    } catch (e) {
      debugPrint('Error fetching requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequestStatus(int id, String userId, String requestedRole, String status) async {
    try {
      await SupabaseService.client
          .from('upgrade_requests')
          .update({'status': status})
          .eq('id', id);

      if (status == 'approved') {
        await SupabaseService.client
            .from('users')
            .update({'role': requestedRole})
            .eq('id', userId);
      }
      
      _fetchRequests(); // refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final req = _requests[index];
              final user = req['users'] ?? {};
              
              return Card(
                margin: const EdgeInsets.all(8),
                color: AppColors.ivorySand,
                child: ListTile(
                  title: Text(user['full_name'] ?? 'Unknown User', style: AppTypography.bodyLg),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${user['email']}'),
                      Text('Requested: ${req['requested_role']}'),
                      Text('Reason: ${req['reason']}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: AppColors.oliveGrove),
                        onPressed: () => _updateRequestStatus(req['id'], req['user_id'], req['requested_role'], 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _updateRequestStatus(req['id'], req['user_id'], req['requested_role'], 'rejected'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
