import 'maintenance_nodes.dart';

extension MaintenanceNodeCounts on MaintenanceNode {
  int get recursiveMajorAssemblyCount {
    int count = 0;
    if (this is MajorAssemblyNode) count = 1; // Though usually called on parent
    for (final child in children) {
      if (child is MajorAssemblyNode) {
        count++;
      }
      count += child.recursiveMajorAssemblyCount;
    }
    return count;
    // Actually, calling on MachineNode, we want counts of children.
    // Adjusted logic:
    // If I am a Machine, I don't count myself.
    // But recursive calls on children should count them.
  }

  // Better implementation:
  // Count specific type in subtree
  int countTypeInSubtree<T>() {
    int count = 0;
    for (final child in children) {
      if (child is T) count++;
      count += child.countTypeInSubtree<T>();
    }
    return count;
  }
}
