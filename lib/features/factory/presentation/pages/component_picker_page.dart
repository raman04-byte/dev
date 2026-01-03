import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../domain/models/maintenance_nodes.dart';
import '../../domain/models/maintenance_extensions.dart';

class ComponentPickerPage extends StatelessWidget {
  final List<MaintenanceNode> nodes;
  final MaintenanceNode? rootNode; // The root machine node (for context/saving)
  final String title;

  const ComponentPickerPage({
    super.key,
    required this.nodes,
    this.rootNode,
    this.title = 'Select Component',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.systemGray6,
              AppColors.white,
              const Color(0xFF7B1FA2).withOpacity(0.05),
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: nodes.isEmpty
              ? const Center(
                  child: Text(
                    'No items found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    return _buildNodeCard(context, node);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(BuildContext context, MaintenanceNode node) {
    final isComponent = node is ComponentNode;
    final color = isComponent ? Colors.purple : AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glassmorphism.card(
        blur: 20,
        opacity: 0.6,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isComponent) {
            // Found a component, return it along with the root
            Navigator.pop(context, {
              'component': node,
              'root':
                  rootNode ?? node, // If picking from root list, node IS root
            });
          } else {
            // Drill down
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComponentPickerPage(
                  nodes: node.children,
                  rootNode: rootNode ?? node, // Preserve root
                  title: node.name,
                ),
              ),
            ).then((result) {
              // Bubble up the result if found
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForNode(node), color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTypeName(node),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isComponent)
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForNode(MaintenanceNode node) {
    if (node is MachineNode) return Icons.precision_manufacturing;
    if (node is MajorAssemblyNode) return Icons.settings_applications;
    if (node is SubAssemblyNode) return Icons.build;
    return Icons.extension;
  }

  String _getTypeName(MaintenanceNode node) {
    if (node is MachineNode) return 'Machine';
    if (node is MajorAssemblyNode) return 'Major Assembly';
    if (node is SubAssemblyNode) return 'Sub Assembly';
    if (node is ComponentNode) return 'Component';
    return 'Item';
  }
}
