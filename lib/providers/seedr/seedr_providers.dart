import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/seedr_service.dart';
import '../../models/seedr_item.dart';
import '../../logging/app_logger.dart';

final seedrServiceProvider = Provider<SeedrService>((ref) {
  return SeedrService();
});

final seedrAccountsProvider = StateNotifierProvider<SeedrAccountsNotifier, List<SeedrAccountState>>((ref) {
  return SeedrAccountsNotifier(ref.read(seedrServiceProvider));
});

class SeedrAccountState {
  final String email;
  final String? label;
  final bool isLoggedIn;
  final SeedrAccount? account;
  final List<SeedrItem> items;
  final bool isLoading;
  final String? error;

  const SeedrAccountState({
    required this.email,
    this.label,
    this.isLoggedIn = false,
    this.account,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  SeedrAccountState copyWith({
    String? email,
    String? label,
    bool? isLoggedIn,
    SeedrAccount? account,
    List<SeedrItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return SeedrAccountState(
      email: email ?? this.email,
      label: label ?? this.label,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      account: account ?? this.account,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SeedrAccountsNotifier extends StateNotifier<List<SeedrAccountState>> {
  final SeedrService _service;
  int _activeAccountIndex = 0;

  SeedrAccountsNotifier(this._service) : super([]) {
    _loadAccounts();
  }

  int get activeAccountIndex => _activeAccountIndex;
  SeedrAccountState? get activeAccount =>
      state.isNotEmpty ? state[_activeAccountIndex.clamp(0, state.length - 1)] : null;

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _service.loadSavedAccounts();
      if (accounts.isEmpty) {
        state = [];
        return;
      }
      state = accounts.map((email) => SeedrAccountState(email: email)).toList();
      for (var i = 0; i < state.length; i++) {
        await _checkAndLoadAccount(i);
      }
    } catch (e) {
      appLogger.e('Failed to load Seedr accounts', error: e);
    }
  }

  Future<void> _checkAndLoadAccount(int index) async {
    if (index >= state.length) return;
    final email = state[index].email;
    final loggedIn = await _service.isLoggedInForAccount(email);
    if (!loggedIn) return;

    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          state[i].copyWith(isLoggedIn: true, isLoading: true)
        else
          state[i],
    ];

    try {
      final account = await _service.getAccount();
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(account: account, isLoading: false, isLoggedIn: true)
          else
            state[i],
      ];
    } catch (e) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(error: e.toString(), isLoading: false)
          else
            state[i],
      ];
    }
  }

  Future<void> addAccount(String email, String password) async {
    try {
      await _service.login(email, password);
      state = [...state, SeedrAccountState(email: email, isLoggedIn: true)];
      await _checkAndLoadAccount(state.length - 1);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeAccount(int index) async {
    if (index >= state.length) return;
    final email = state[index].email;
    await _service.removeAccount(email);
    state = [...state.take(index), ...state.skip(index + 1)];
    if (_activeAccountIndex >= state.length && state.isNotEmpty) {
      _activeAccountIndex = state.length - 1;
    }
  }

  void switchAccount(int index) {
    if (index >= 0 && index < state.length) {
      _activeAccountIndex = index;
    }
  }

  Future<void> logoutAccount(int index) async {
    if (index >= state.length) return;
    await _service.logout();
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          SeedrAccountState(email: state[i].email, label: state[i].label)
        else
          state[i],
    ];
  }

  void updateLabel(int index, String label) {
    if (index >= state.length) return;
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          state[i].copyWith(label: label)
        else
          state[i],
    ];
  }
}

final seedrContentsProvider = StateNotifierProvider.family<SeedrContentsNotifier, SeedrContentsState, int?>((ref, folderId) {
  return SeedrContentsNotifier(ref.read(seedrServiceProvider), folderId);
});

class SeedrContentsState {
  final List<SeedrItem> items;
  final bool isLoading;
  final String? error;

  const SeedrContentsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  SeedrContentsState copyWith({
    List<SeedrItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return SeedrContentsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SeedrContentsNotifier extends StateNotifier<SeedrContentsState> {
  final SeedrService _service;
  final int? _folderId;

  SeedrContentsNotifier(this._service, this._folderId) : super(const SeedrContentsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.listContents(folderId: _folderId);
      state = SeedrContentsState(items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
