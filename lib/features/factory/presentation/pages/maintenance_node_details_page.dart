import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../domain/models/maintenance_nodes.dart';
import '../../domain/models/maintenance_extensions.dart';
import 'add_child_node_page.dart';
import 'add_machine_page.dart';

class MaintenanceNodeDetailsPage extends StatefulWidget {
  final MaintenanceNode node;
  final MaintenanceNode rootNode; // Needed for saving the tree

  const MaintenanceNodeDetailsPage({
    super.key,
    required this.node,
    required this.rootNode,
  });

  @override
  State<MaintenanceNodeDetailsPage> createState() =>
      _MaintenanceNodeDetailsPageState();
}

class _MaintenanceNodeDetailsPageState
    extends State<MaintenanceNodeDetailsPage> {
  late MaintenanceNode currentNode;

  @override
  void initState() {
    super.initState();
    currentNode = widget.node;
  }

  Future<void> _saveTree() async {
    if (widget.rootNode.isInBox) {
      await widget.rootNode.save();
    }
  }

  Future<void> _addChild(Type type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddChildNodePage(nodeType: type)),
    );

    if (result is MaintenanceNode) {
      setState(() {
        currentNode.children.add(result);
      });
      await _saveTree();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      }
    }
  }

  Future<void> _editCurrentNode() async {
    if (currentNode is MachineNode) {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddMachinePage(machine: currentNode as MachineNode),
        ),
      );
      if (res == true) {
        if (mounted) Navigator.pop(context);
        return;
      }
    } else {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddChildNodePage(
            nodeType: currentNode.runtimeType,
            node: currentNode,
          ),
        ),
      );

      if (res is MaintenanceNode) {
        setState(() {
          currentNode = res;
        });
        if (mounted) {
          Navigator.pop(context, currentNode);
        }
      }
    }
  }

  Future<void> _deleteCurrentNode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${currentNode.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        Navigator.pop(context, 'delete');
      }
    }
  }

  Future<void> _editChild(int index) async {
    final child = currentNode.children[index];
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddChildNodePage(nodeType: child.runtimeType, node: child),
      ),
    );

    if (res is MaintenanceNode) {
      setState(() {
        currentNode.children[index] = res;
      });
      await _saveTree();
    }
  }

  Future<void> _deleteChild(int index) async {
    final child = currentNode.children[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${child.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        currentNode.children.removeAt(index);
      });
      await _saveTree();
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Glassmorphism.card(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (currentNode is MachineNode) ...[
                _buildAddOption(
                  'Major Assembly',
                  Icons.settings_applications,
                  MajorAssemblyNode,
                ),
                _buildAddOption('Sub Assembly', Icons.build, SubAssemblyNode),
                _buildAddOption('Component', Icons.extension, ComponentNode),
              ] else if (currentNode is MajorAssemblyNode) ...[
                _buildAddOption('Sub Assembly', Icons.build, SubAssemblyNode),
                _buildAddOption('Component', Icons.extension, ComponentNode),
              ] else if (currentNode is SubAssemblyNode) ...[
                _buildAddOption('Component', Icons.extension, ComponentNode),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(String label, IconData icon, Type type) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryBlue),
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // Close sheet
        _addChild(type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComponent = currentNode is ComponentNode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentNode.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (isComponent) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.textPrimary),
              onPressed: _editCurrentNode,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteCurrentNode,
            ),
          ] else if (currentNode is MachineNode) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editCurrentNode,
            ),
          ],
        ],
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: (!isComponent)
          ? FloatingActionButton.extended(
              onPressed: _showAddOptions,
              backgroundColor: AppColors.primaryBlue,
              icon: const Icon(Icons.add),
              label: const Text('Add Child'),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.systemGray6,
              AppColors.white,
              const Color(0xFF7B1FA2).withOpacity(0.02),
              AppColors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: isComponent
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildComponentFullDetails(),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(child: _buildHeaderCard()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Children (${currentNode.children.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (currentNode.children.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No items yet',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final child = currentNode.children[index];
                          return _buildChildCard(child, index);
                        }, childCount: currentNode.children.length),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildComponentFullDetails() {
    final c = currentNode as ComponentNode;

    // Safety checks for rendering
    final criticalityName = c.criticality.name.toUpperCase();

    return Glassmorphism.card(
      padding: const EdgeInsets.all(24),
      blur: 20,
      opacity: 0.6,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.extension,
                  size: 40,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Component',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('General Info'),
          _buildInfoRow('Model Number', c.modelNumber),
          _buildInfoRow('Brand/Manuf.', c.manufacturerOrBrand),
          _buildInfoRow('Specification', c.specification),

          const SizedBox(height: 24),
          _buildSectionHeader('Inventory'),
          _buildInfoRow('Location', c.location),
          _buildInfoRow('Stock Quantity', '${c.currentStockQuantity}'),
          _buildInfoRow('Reorder Level', '${c.reorderLevel}'),
          _buildInfoRow(
            'Shelf Life',
            c.shelfLifeDays != null ? '${c.shelfLifeDays} days' : 'N/A',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Maintenance'),
          _buildInfoRow('Criticality', criticalityName),
          _buildInfoRow('Cycle', '${c.maintenanceCycleDays} days'),
          _buildInfoRow(
            'Last Maint.',
            c.lastMaintenanceDate != null
                ? DateFormat('MMM dd, yyyy').format(c.lastMaintenanceDate!)
                : 'Never',
          ),
          _buildInfoRow(
            'Next Maint.',
            c.nextMaintenanceDate != null
                ? DateFormat('MMM dd, yyyy').format(c.nextMaintenanceDate!)
                : 'N/A',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Suppliers'),
          if (c.suppliers.isEmpty)
            const Text(
              'No suppliers added',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...c.suppliers.map((s) => _buildSupplierCard(s)),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Supplier s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (s.lastPurchasedRate != null)
                Text(
                  '₹ ${s.lastPurchasedRate}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSupplierRow(Icons.location_on, s.address),
          _buildSupplierRow(Icons.person, s.contactName),
          _buildSupplierRow(Icons.phone, s.contactNumber),
        ],
      ),
    );
  }

  Widget _buildSupplierRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  // Used for non-component nodes
  Widget _buildHeaderCard() {
    return Glassmorphism.card(
      padding: const EdgeInsets.all(24),
      blur: 20,
      opacity: 0.6,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getIconForNode(currentNode),
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentNode.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _getTypeName(currentNode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailContent(),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    if (currentNode is MachineNode) {
      final m = currentNode as MachineNode;
      return Column(
        children: [
          _buildInfoRow('Code', m.code),
          _buildInfoRow('Status', m.currentStatus.name.toUpperCase()),
          _buildInfoRow('Location', m.location),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(MaintenanceNode child, int index) {
    int subCount = 0;
    int compCount = 0;

    if (child is MajorAssemblyNode) {
      subCount = child.countTypeInSubtree<SubAssemblyNode>();
      compCount = child.countTypeInSubtree<ComponentNode>();
    } else if (child is SubAssemblyNode) {
      compCount = child.countTypeInSubtree<ComponentNode>();
    }

    final color = AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Glassmorphism.card(
        blur: 20,
        opacity: 0.6,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaintenanceNodeDetailsPage(
                  node: child,
                  rootNode: widget.rootNode,
                ),
              ),
            );

            if (result == 'delete') {
              setState(() {
                currentNode.children.removeAt(index);
              });
              await _saveTree();
            } else if (result is MaintenanceNode) {
              setState(() {
                currentNode.children[index] = result;
              });
              await _saveTree();
            } else {
              setState(() {});
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForNode(child),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getTypeName(child),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (subCount > 0 || compCount > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (subCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildCountBadge(
                            'Subs',
                            subCount,
                            Colors.orange,
                          ),
                        ),
                      if (compCount > 0)
                        _buildCountBadge('Parts', compCount, Colors.purple),
                    ],
                  ),
                ],

                if (child is ComponentNode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${child.currentStockQuantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _editChild(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteChild(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    if (node is MajorAssemblyNode) return 'Major Assembly';
    if (node is SubAssemblyNode) return 'Sub Assembly';
    if (node is ComponentNode) return 'Component';
    return 'Item';
  }
}
