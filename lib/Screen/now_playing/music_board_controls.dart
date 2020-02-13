import 'package:flute_music_player/flute_music_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:ringtone_app/blocs/global.dart';
import 'package:ringtone_app/model/playerstate.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MusicBoardControls extends StatefulWidget {
  bool isRingtone;
  MusicBoardControls({this.isRingtone});


  MusicBoardControlsState createState() => MusicBoardControlsState();
}

class MusicBoardControlsState extends State<MusicBoardControls> {
  @override
  Widget build(BuildContext context) {
    final GlobalBloc _globalBloc = Provider.of<GlobalBloc>(context);
    return Container(
      height: 100,
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 245,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xFFFEDCDC),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(2, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: GestureDetector(
                      onTap: () =>
                      widget.isRingtone ?
                          _globalBloc.musicPlayerBloc.playPreviousSong() : _globalBloc.musicPlayerSongBloc.playPreviousSong(),
                      child: Icon(
                        Icons.fast_rewind,
                        color: Color(0xFFFD9D9D),
                        size: 40,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => widget.isRingtone ? _globalBloc.musicPlayerBloc.playNextSong() : _globalBloc.musicPlayerSongBloc.playNextSong(),
                      child: Icon(
                        Icons.fast_forward,
                        color: Color(0xFFFD9D9D),
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: StreamBuilder<MapEntry<PlayerState, Song>>(
                stream: widget.isRingtone ? _globalBloc.musicPlayerBloc.playerState$ : _globalBloc.musicPlayerSongBloc.playerState$,
                builder: (BuildContext context,
                    AsyncSnapshot<MapEntry<PlayerState, Song>> snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  final PlayerState _state = snapshot.data.key;
                  final Song _currentSong = snapshot.data.value;
                  return GestureDetector(
                    onTap: () {
                      if (_currentSong.uri == null) {
                        return;
                      }
                      if (PlayerState.paused == _state) {
                        widget.isRingtone ?
                        _globalBloc.musicPlayerBloc.playMusic(_currentSong) :
                        _globalBloc.musicPlayerSongBloc.playMusic(_currentSong);
                      } else {
                        widget.isRingtone ?
                        _globalBloc.musicPlayerBloc.pauseMusic(_currentSong) :
                        _globalBloc.musicPlayerSongBloc.pauseMusic(_currentSong);
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: Offset(2, 1.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedCrossFade(
                          duration: Duration(milliseconds: 200),
                          crossFadeState: _state == PlayerState.playing
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Icon(
                            Icons.pause,
                            size: 50,
                            color: Color(0xFFFD9D9D),
                          ),
                          secondChild: Icon(
                            Icons.play_arrow,
                            size: 50,
                            color: Color(0xFFFD9D9D),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
