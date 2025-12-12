import '../models/party_model.dart';

abstract class PartyRepository {
  Future<String> createParty(PartyModel party);
  Future<List<PartyModel>> getAllParties();
  Future<List<PartyModel>> getPartiesByState(String state);
  Future<PartyModel> getPartyById(String id);
  Future<void> updateParty(String id, PartyModel party);
  Future<void> deleteParty(String id);
  Future<Map<String, String>?> getPincodeDetails(String pincode);
  Future<Map<String, String>?> getGSTDetails(String gstNumber);
}
