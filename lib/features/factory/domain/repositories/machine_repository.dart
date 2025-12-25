import '../models/machine_model.dart';

abstract class MachineRepository {
  Future<void> addMachine(MachineModel machine);
  Future<List<MachineModel>> getAllMachines();
  Future<List<MachineModel>> getSubComponents(String parentId);
  Future<void> updateMachine(MachineModel machine);
  Future<void> deleteMachine(String id);
}
