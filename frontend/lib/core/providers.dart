import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState {
	final String name;
	final String email;
	final String profilePicture;

	ProfileState({this.name = '', this.email = '', this.profilePicture = ''});

	ProfileState copyWith({String? name, String? email, String? profilePicture}) {
		return ProfileState(
			name: name ?? this.name,
			email: email ?? this.email,
			profilePicture: profilePicture ?? this.profilePicture,
		);
	}
}

class ProfileNotifier extends StateNotifier<ProfileState> {
	ProfileNotifier(): super(ProfileState()) {
		_loadFromPrefs();
	}

	Future<void> _loadFromPrefs() async {
		final prefs = await SharedPreferences.getInstance();
		final name = prefs.getString('user_name') ?? '';
		final email = prefs.getString('user_email') ?? '';
		final picture = prefs.getString('profile_picture') ?? '';
		state = ProfileState(name: name, email: email, profilePicture: picture);
	}

	Future<void> refresh() async {
		await _loadFromPrefs();
	}

	Future<void> setProfile({String? name, String? email, String? profilePicture}) async {
		final prefs = await SharedPreferences.getInstance();
		if (name != null) await prefs.setString('user_name', name);
		if (email != null) await prefs.setString('user_email', email);
		if (profilePicture != null) await prefs.setString('profile_picture', profilePicture);

		state = state.copyWith(name: name, email: email, profilePicture: profilePicture);
	}
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
	return ProfileNotifier();
});



