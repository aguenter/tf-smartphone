import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/supabase_service.dart';
import 'app_event.dart';
import 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required SupabaseService supabaseService})
      : _supabaseService = supabaseService,
        super(const AppLoadingState()) {
    on<AppStarted>(_onAppStarted);
  }

  final SupabaseService _supabaseService;

  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    await _supabaseService.connect();
    emit(const AppReadyState());
  }
}
