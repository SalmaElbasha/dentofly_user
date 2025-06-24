
import '../repositories/governate_repository_interface.dart';
import 'governate_service_interface.dart';

class GovernateService implements GovernateServiceInterface {
  final GovernateRepositoryInterface governateRepo;

  GovernateService({required this.governateRepo});

  @override
  Future<void> saveGovernate(dynamic name) {
    return governateRepo.saveGovernate(name);
  }

  @override
  String? getGovernate() {
    return governateRepo.getGovernate();
  }
}
