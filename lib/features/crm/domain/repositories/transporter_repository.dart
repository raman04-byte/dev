import '../models/transporter_model.dart';

abstract class TransporterRepository {
  Future<String> createTransporter(TransporterModel transporter);
  Future<List<TransporterModel>> getAllTransporters();
  Future<TransporterModel> getTransporterById(String id);
  Future<void> updateTransporter(String id, TransporterModel transporter);
  Future<void> deleteTransporter(String id);
}
