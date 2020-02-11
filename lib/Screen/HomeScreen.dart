import 'package:flutter/material.dart';
import 'package:ringtone_app/model/Album.dart';
import 'package:ringtone_app/blocs/global.dart';
import 'package:provider/provider.dart';
import 'package:ringtone_app/common/empty_screen.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flute_music_player/flute_music_player.dart';
import 'package:ringtone_app/blocs/global.dart';
import 'package:ringtone_app/common/empty_screen.dart';
import 'package:ringtone_app/model/playerstate.dart';
import 'package:ringtone_app/Screen/Offline/Song_Title.dart';


import 'package:flutter/services.dart';



class HomeScreen extends StatefulWidget {

  bool isOpen;

  HomeScreen(this.isOpen);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {

  Widget OfflineHome(BuildContext context){
    final GlobalBloc _globalBloc = Provider.of<GlobalBloc>(context);


    // TODO: implement build
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final double _radius = 25.0;
    PanelController _panelController;

    @override
    void initState() {
      _panelController = PanelController();

      super.initState();
    }

    @override
    void dispose() {
      _panelController.close();
      super.dispose();
    }
    return  WillPopScope(
      onWillPop: () {
        if (!_panelController.isPanelClosed()) {
          _panelController.close();
        } else {
          _showExitDialog();
        }
      },
      child: Scaffold(
        body:  SlidingUpPanel(
          panel: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_radius),
              topRight: Radius.circular(_radius),
            ),
          //  child: NowPlayingScreen(controller: _panelController),
          ),
          controller: _panelController,
          minHeight: 130,
          maxHeight: MediaQuery.of(context).size.height,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_radius),
            topRight: Radius.circular(_radius),
          ),
          collapsed: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_radius),
                topRight: Radius.circular(_radius),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  0.0,
                  0.7,
                ],
                colors: [
                  Color(0xFFFD9D9D),
                  Color(0xFF8A8A8A),
                ],
              ),
            ),
            //child: BottomPanel(controller: _panelController),
          ),
          body:  Container(
              decoration: BoxDecoration(
              color: Colors.red,
              image: DecorationImage(
              image: AssetImage("assets/images/bg.png"),
              fit: BoxFit.cover,

              )
            ),
          child:  StreamBuilder<List<Song>>(
            stream: _globalBloc.musicPlayerBloc.songs$,
            builder: (BuildContext context, AsyncSnapshot<List<Song>> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              final List<Song> _songs = snapshot.data;
              if (_songs.length == 0) {
                return EmptyScreen(
                  text: "You do not have any songs on your device.",
                );
              }
              return ListView.builder(
                key: PageStorageKey<String>("All Songs"),
                padding: const EdgeInsets.only(bottom: 150.0),
                physics: BouncingScrollPhysics(),
                itemCount: _songs.length,
                itemExtent: 100,
                itemBuilder: (BuildContext context, int index) {
                  return StreamBuilder<MapEntry<PlayerState, Song>>(
                    stream: _globalBloc.musicPlayerBloc.playerState$,
                    builder: (BuildContext context,
                        AsyncSnapshot<MapEntry<PlayerState, Song>> snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      final PlayerState _state = snapshot.data.key;
                      final Song _currentSong = snapshot.data.value;
                      final bool _isSelectedSong = _currentSong == _songs[index];
                      return GestureDetector(
                        onTap: () {
                          _globalBloc.musicPlayerBloc.updatePlaylist(_songs);
                          switch (_state) {
                            case PlayerState.playing:
                              if (_isSelectedSong) {
                                _globalBloc.musicPlayerBloc
                                    .pauseMusic(_currentSong);
                              } else {
                                _globalBloc.musicPlayerBloc.stopMusic();
                                _globalBloc.musicPlayerBloc.playMusic(
                                  _songs[index],
                                );
                              }
                              break;
                            case PlayerState.paused:
                              if (_isSelectedSong) {
                                _globalBloc.musicPlayerBloc
                                    .playMusic(_songs[index]);
                              } else {
                                _globalBloc.musicPlayerBloc.stopMusic();
                                _globalBloc.musicPlayerBloc.playMusic(
                                  _songs[index],
                                );
                              }
                              break;
                            case PlayerState.stopped:
                              _globalBloc.musicPlayerBloc.playMusic(_songs[index]);
                              break;
                            default:
                              break;
                          }
                        },
                        child: SongTile(
                          song: _songs[index],
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
          )
        ),
      ),
    );
  }

  Widget OnlineHome(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        color: Colors.amber,
      ),
    );
  }
  void _showExitDialog() {
    final GlobalBloc _globalBloc = Provider.of<GlobalBloc>(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'BTS Ringtones',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          content: Text(
            "If you like this app, please take a little bit of your time to review it !\nIt really helps us and it shouldn\'t take you more than one minute.",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              textColor: Color(0xFFDF5F9D),
              onPressed: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                _globalBloc.dispose();
              },
              child: Text("EXIT"),
            ),
            FlatButton(
              textColor: Color(0xFFDF5F9D),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("CANCEL"),
            ),
            FlatButton(
              textColor: Color(0xFFDF5F9D),
              onPressed: () async {
                RateMyApp rateMyApp = RateMyApp();
                await rateMyApp.launchStore();
              },
              child: Text("RATE"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {


    // TODO: implement build
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;


    return Scaffold(
      body: widget.isOpen ? OnlineHome(context) : OfflineHome(context)
    );
  }
}
