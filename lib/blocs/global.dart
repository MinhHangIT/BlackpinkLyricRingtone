import 'package:ringtone_app/blocs/music_player.dart';
import 'package:ringtone_app/blocs/permissions.dart';
import 'package:ringtone_app/blocs/music_player_songs.dart';


class GlobalBloc {
  PermissionsBloc _permissionsBloc;
  MusicPlayerBloc _musicPlayerBloc;
  MusicPlayerBloc get musicPlayerBloc => _musicPlayerBloc;
  PermissionsBloc get permissionsBloc => _permissionsBloc;
  MusicPlayerBloc _musicPlayerSongBloc;
  MusicPlayerBloc get musicPlayerSongBloc => _musicPlayerSongBloc;

  GlobalBloc() {
    _musicPlayerBloc = MusicPlayerBloc();
    _musicPlayerSongBloc = MusicPlayerBloc();
    _permissionsBloc = PermissionsBloc();
  }

  void dispose() {
    _musicPlayerBloc.dispose();
    _permissionsBloc.dispose();
    _musicPlayerSongBloc.dispose();

  }
}
