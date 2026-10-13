import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/patient_draft.dart';

/// Online identity bootstrap. POST /patients has no client-ID/idempotent batch
/// contract, so it is never queued or automatically replayed in the outbox.
class PatientRepository {
  PatientRepository(this.client);
  final ApiClient client;

  Future<String> create(PatientDraft draft) async {
    final response = await client.request<dynamic>(
      '/patients',
      credential: ApiCredential.caregiver,
      method: 'POST',
      data: draft.toJson(),
    );
    final data = response.data;
    if (response.statusCode != 201 ||
        data is! Map ||
        data['id'] is! String ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(data['id'] as String)) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return data['id'] as String;
  }
}
