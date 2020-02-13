import 'dart:async';

import 'package:flute_music_player/flute_music_player.dart';
import 'package:flutter/services.dart';
import 'package:ringtone_app/model/Album.dart';
import 'package:ringtone_app/model/playback.dart';
import 'package:ringtone_app/model/playerstate.dart';
import 'package:ringtone_app/model/SongLyric.dart';
import 'package:ringtone_app/constant/app_constant.dart';
import 'package:ringtone_app/utils/directory_modul.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MusicPlayerBloc {
  BehaviorSubject<List<Song>> _songs$;
  BehaviorSubject<List<Song>> _localSongs$;
  BehaviorSubject<List<SongLyric>> _songLyric$;
  BehaviorSubject<List<Album>> _albums$;
  BehaviorSubject<MapEntry<PlayerState, Song>> _playerState$;
  BehaviorSubject<MapEntry<List<Song>, List<Song>>>
      _playlist$; //key is normal, value is shuffle
  BehaviorSubject<Duration> _position$;
  BehaviorSubject<List<Playback>> _playback$;
  BehaviorSubject<List<Song>> _favorites$;
  BehaviorSubject<bool> _isAudioSeeking$;
  MusicFinder _audioPlayer;
  Song _defaultSong;
  Map<String, SongLyric> hashMySong;

  BehaviorSubject<List<Song>> get songs$ => _songs$;

  BehaviorSubject<List<Song>> get localSongs$ => _localSongs$;

  BehaviorSubject<List<SongLyric>> get songLyric$ => _songLyric$;

  BehaviorSubject<List<Album>> get albums$ => _albums$;

  BehaviorSubject<MapEntry<PlayerState, Song>> get playerState$ =>
      _playerState$;

  BehaviorSubject<Duration> get position$ => _position$;

  BehaviorSubject<List<Playback>> get playback$ => _playback$;

  BehaviorSubject<List<Song>> get favorites$ => _favorites$;

  MusicPlayerBloc() {
    _initDeafultSong();
    _initStreams();
    _initObservers();
    _initAudioPlayer();
  }

  Future<void> fetchSongs() async {
    String jsonString = await rootBundle.loadString('lib/data/song.json');
    List<Song> mySongs = new List<Song>();
    final jsonResponse = json.decode(jsonString);
    hashMySong = new Map<String, SongLyric>();
    List<Song> songs = new List<Song>();
    jsonResponse.forEach((o) {
      SongLyric mySong = SongLyric.fromJson(o);
      Song song = Song.fromMap(o);
      //song.isLocal = false;
      songs.add(song);
      hashMySong[mySong.key] = mySong;
    });
    _songs$.add(songs);
  }

  Future<void> fetchRingtones() async {
    String jsonString = await rootBundle.loadString('lib/data/ringtone.json');
    final jsonResponse = json.decode(jsonString);
    List<Song> mySongs = new List<Song>();
    jsonResponse.forEach((o) {
      mySongs.add(Song.fromMap(o));
    });
    _songs$.add(mySongs);
  }

  Future<void> fetchLocalSongs() async {
    print("--------------------------------------");
    await MusicFinder.allSongs().then(
      (data) {
        data = jsonDecode(data);
        print("--------------------------------------");
        print(data.length);
        List<Song> songs = new List<Song>();
        data.forEach((song) {
          if (song.uri.contains(FOLDER_NAME)) {
            song.isLocal = true;
            song.key = getKeyFromUri(song.uri);
            // print(jsonEncode(song.toJson()));
            songs.add(song);
          }
        });
        _localSongs$.add(songs);
      },
    );
  }

  Future<void> removeFromLocal(Song song) async {
    await DirectoryModule.deleteFile(song.uri).then((_) async {
      Timer(Duration(seconds: 1), () async {
        await fetchLocalSongs();
      });
    });
  }

  void playMusic(Song song) {
    _audioPlayer.play(song.uri);
    updatePlayerState(PlayerState.playing, song);
  }

  void pauseMusic(Song song) {
    _audioPlayer.pause();
    updatePlayerState(PlayerState.paused, song);
  }

  void stopMusic() {
    _audioPlayer.stop();
  }

  void updatePlayerState(PlayerState state, Song song) {
    _playerState$.add(MapEntry(state, song));
  }

  void updatePosition(Duration duration) {
    _position$.add(duration);
  }

  void updatePlaylist(List<Song> normalPlaylist) {
    List<Song> _shufflePlaylist = []..addAll(normalPlaylist);
    _shufflePlaylist.shuffle();
    _playlist$.add(MapEntry(normalPlaylist, _shufflePlaylist));
  }

  void _updateAlbums(List<Song> songs) {
    Map<int, Album> _albumsMap = {};
    for (Song song in songs) {
      if (_albumsMap[song.albumId] == null) {
        _albumsMap[song.albumId] = Album.fromSong(song);
      }
    }
    final List<Album> _albums = _albumsMap.values.toList();
    _albums$.add(_albums);
  }

  void playNextSong() {
    if (_playerState$.value.key == PlayerState.stopped) {
      return;
    }
    final Song _currentSong = _playerState$.value.value;
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Song> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexOf(_currentSong);
    if (_index == _playlist.length - 1) {
      _index = 0;
    } else {
      _index++;
    }
    stopMusic();
    playMusic(_playlist[_index]);
  }

  void playPreviousSong() {
    if (_playerState$.value.key == PlayerState.stopped) {
      return;
    }
    final Song _currentSong = _playerState$.value.value;
    final bool _isShuffle = _playback$.value.contains(Playback.shuffle);
    final List<Song> _playlist =
        _isShuffle ? _playlist$.value.value : _playlist$.value.key;
    int _index = _playlist.indexOf(_currentSong);
    if (_index == 0) {
      _index = _playlist.length - 1;
    } else {
      _index--;
    }
    stopMusic();
    playMusic(_playlist[_index]);
  }

  void _playSameSong() {
    final Song _currentSong = _playerState$.value.value;
    stopMusic();
    playMusic(_currentSong);
  }

  void _onSongComplete() {
    final List<Playback> _playback = _playback$.value;
    if (_playback.contains(Playback.repeatSong)) {
      _playSameSong();
      return;
    }
    playNextSong();
  }

  void audioSeek(double seconds) {
    _audioPlayer.seek(seconds);
  }

  void addToFavorites(Song song) async {
    List<Song> _favorites = _favorites$.value;
    _favorites.add(song);
    _favorites$.add(_favorites);
    await saveFavorites();
  }

  void removeFromFavorites(Song song) async {
    List<Song> _favorites = _favorites$.value;
    _favorites.remove(song);
    _favorites$.add(_favorites);
    await saveFavorites();
  }

  void invertSeekingState() {
    final _value = _isAudioSeeking$.value;
    _isAudioSeeking$.add(!_value);
  }

  void updatePlayback(Playback playback) {
    List<Playback> _value = playback$.value;
    if (playback == Playback.shuffle) {
      final List<Song> _normalPlaylist = _playlist$.value.key;
      updatePlaylist(_normalPlaylist);
    }
    _value.add(playback);
    _playback$.add(_value);
  }

  void removePlayback(Playback playback) {
    List<Playback> _value = playback$.value;
    _value.remove(playback);
    _playback$.add(_value);
  }

  Future<void> saveFavorites() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Song> _favorites = _favorites$.value;
    List<String> _encodedStrings = [];
    for (Song song in _favorites) {
      _encodedStrings.add(_encodeSongToJson(song));
    }
    _prefs.setStringList("favorites", _encodedStrings);
  }

  void retrieveFavorites() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final List<Song> _fetchedSongs = _songs$.value;
    List<String> _savedStrings = _prefs.getStringList("favorites") ?? [];
    List<Song> _favorites = [];
    for (String data in _savedStrings) {
      final Song song = _decodeSongFromJson(data);
      for (var fetchedSong in _fetchedSongs) {
        if (song.id == fetchedSong.id) {
          _favorites.add(fetchedSong);
        }
      }
    }
    _favorites$.add(_favorites);
  }

  String _encodeSongToJson(Song song) {
    final _songMap = songToMap(song);
    final data = json.encode(_songMap);
    return data;
  }

  Song _decodeSongFromJson(String ecodedSong) {
    final _songMap = json.decode(ecodedSong);
    final Song _song = Song.fromMap(_songMap);
    return _song;
  }

  Map<String, dynamic> songToMap(Song song) {
    Map<String, dynamic> _map = {};
    _map["album"] = song.album;
    _map["id"] = song.id;
    _map["artist"] = song.artist;
    _map["title"] = song.title;
    _map["albumId"] = song.albumId;
    _map["duration"] = song.duration;
    _map["uri"] = song.uri;
    _map["albumArt"] = song.albumArt;
    return _map;
  }

  void _initDeafultSong() {
    _defaultSong = Song(null, " ", " ", " ", null, null, null, null);
  }

  void _initObservers() {
    _songs$.listen(
      (List<Song> songs) {
        _updateAlbums(songs);
      },
    ); // push albums from songs
  }

  void _initStreams() {
    _isAudioSeeking$ = BehaviorSubject<bool>.seeded(false);
    _songs$ = BehaviorSubject<List<Song>>();
    _albums$ = BehaviorSubject<List<Album>>();
    _localSongs$ = BehaviorSubject<List<Song>>();

    _position$ = BehaviorSubject<Duration>();
    _playlist$ = BehaviorSubject<MapEntry<List<Song>, List<Song>>>();
    _playback$ = BehaviorSubject<List<Playback>>.seeded([]);
    _favorites$ = BehaviorSubject<List<Song>>.seeded([]);
    _playerState$ = BehaviorSubject<MapEntry<PlayerState, Song>>.seeded(
      MapEntry(
        PlayerState.stopped,
        _defaultSong,
      ),
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = MusicFinder();
    _audioPlayer.setPositionHandler(
      (Duration duration) {
        final bool _isAudioSeeking = _isAudioSeeking$.value;
        if (!_isAudioSeeking) {
          updatePosition(duration);
        }
      },
    );
    _audioPlayer.setCompletionHandler(
      () {
        _onSongComplete();
      },
    );
  }

  void dispose() {
    stopMusic();
    _isAudioSeeking$.close();
    _songs$.close();
    _albums$.close();
    _localSongs$.close();
    _playerState$.close();
    _playlist$.close();
    _position$.close();
    _playback$.close();
    _favorites$.close();
  }
}

String getKeyFromUri(String uri) {
  return uri.split('/').last.split('_')[0];
}
