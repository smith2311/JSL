import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/repo/jhaveri_picks_repo.dart';
import '../core/config/env.dart';

final jhaveriPicksRepoProvider = Provider<JhaveriPicksRepo>((ref) {
  return JhaveriPicksRepo(baseUrl: EnvConfig.apiBaseUrl);
});