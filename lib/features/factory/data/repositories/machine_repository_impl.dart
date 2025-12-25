import '../../../../core/services/cache_service.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/repositories/machine_repository.dart';

class MachineRepositoryImpl implements MachineRepository {
  @override
  Future<void> addMachine(MachineModel machine) async {
    final box = CacheService.machineBox;
    await box.put(machine.id, machine);
  }

  @override
  Future<List<MachineModel>> getAllMachines() async {
    final box = CacheService.machineBox;
    // Return only top-level machines (no parentId or isChild is false)
    return box.values.where((m) => !m.isChild).toList();
  }

  @override
  Future<List<MachineModel>> getSubComponents(String parentId) async {
    final box = CacheService.machineBox;
    return box.values.where((m) => m.parentId == parentId).toList();
  }

  @override
  Future<void> updateMachine(MachineModel machine) async {
    final box = CacheService.machineBox;
    await box.put(machine.id, machine);
  }

  @override
  Future<void> deleteMachine(String id) async {
    final box = CacheService.machineBox;
    await box.delete(id);

    // Also delete children?
    // For now, let's keep it simple. But ideally we should delete children recursively.
    final children = box.values.where((m) => m.parentId == id).toList();
    for (var child in children) {
      await deleteMachine(child.id);
    }
  }
}
