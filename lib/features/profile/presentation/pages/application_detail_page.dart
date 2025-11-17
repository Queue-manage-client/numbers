import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:numbers/core/widgets/app_footer.dart';

class ApplicationDetailPage extends StatelessWidget {
  const ApplicationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      bottomNavigationBar: AppFooter(currentRoute: currentRoute),
      body: const Center(
        child: Text('Application Detail Page'),
      ),
    );
  }
}
