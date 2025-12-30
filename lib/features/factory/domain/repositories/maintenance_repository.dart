import '../models/maintenance_nodes.dart';

abstract class MaintenanceRepository {
  Future<void> saveNode(MaintenanceNode node);
  Future<void> deleteNode(String id);
  Future<List<MachineNode>> getAllMachines();
  // We generally only fetch root nodes (Machines) and traverse down,
  // but if needed we can add specific finders.
}
