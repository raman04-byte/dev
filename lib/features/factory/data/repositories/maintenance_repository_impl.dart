import '../../../../core/services/cache_service.dart';
import '../../domain/models/maintenance_nodes.dart';
import '../../domain/repositories/maintenance_repository.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  @override
  Future<void> saveNode(MaintenanceNode node) async {
    final box = CacheService.maintenanceBox;
    await box.put(node.id, node);
  }

  @override
  Future<void> deleteNode(String id) async {
    final box = CacheService.maintenanceBox;
    await box.delete(id);
  }

  @override
  Future<List<MachineNode>> getAllMachines() async {
    final box = CacheService.maintenanceBox;
    // We assume only MachineNodes are stored at the top level in this box
    // or filter them if we decide to store orphaned components (unlikely in this design)
    return box.values.whereType<MachineNode>().toList();
  }
}
