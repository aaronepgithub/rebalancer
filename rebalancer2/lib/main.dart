import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'globals.dart' as globals;
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rebalancer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Rebalancer Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    _fabPressed();

    setState(() {
      str1 = "Starting Data Gathering...";
    }); //

    super.initState();
  }

//FIRST ASYNC - GET LIST OF STATIONS
  Future<String> firstAsync() async {
    print("firstAsync");

    if (globals.stationInfo.length > 900) {
      print('Station data already available');
      return "data already available";
    }

    final stationListAPIUrl =
        'https://gbfs.citibikenyc.com/gbfs/es/station_information.json';
    final response = await http.get(stationListAPIUrl);

    if (response.statusCode == 200) {
      var jsonResponse1 = json.decode(response.body);
      var jsonResponse2 = jsonResponse1['data']['stations'];

      setState(() {
        str1 = "Station Data Received...";
      }); //

      var _list1 = [];

      for (var s2 in jsonResponse2) {
        _list1.add(s2);
      }
      globals.stationInfo = _list1;

      var _listOfStationObjects = [];
      var i = 0;

      for (var _l1 in _list1) {
        Station s = new Station(
            stationId: int.parse(_l1['station_id']),
            name: _l1['name'],
            lat: _l1['lat'].toString(),
            lon: _l1['lon'].toString(),
            isSelected: i);

        _listOfStationObjects.add(s);
        i = 0;
      }
      return ("Number of Station Objects: ${_listOfStationObjects.length}");
    } else {
      throw Exception('Failed to load stations from API');
    }
  }

  //SECOND ASYNC
  Future<String> secondAsync() async {
    print("secondAsync");

    //clear globals
    globals.realtimeStationData = [];
    globals.stationsNearMe = [];
    globals.theStationsNearMe = [];
    globals.theStationsNearMeWith12Bikes = [];
    globals.theStationsNearMeWith12Docks = [];
    globals.theBestRoutes = [];

    final realtimeStationListAPIUrl =
        'https://gbfs.citibikenyc.com/gbfs/en/station_status.json';
    final realtimeResponse = await http.get(realtimeStationListAPIUrl);

    setState(() {
      str1 = "Requesting Real-time Station Status...";
    }); //

    if (realtimeResponse.statusCode == 200) {
      var jsonResponse11 = json.decode(realtimeResponse.body);
      var jsonResponse12 = jsonResponse11['data']['stations'];

      var _list11 = [];

      for (var s12 in jsonResponse12) {
        _list11.add(s12);
      }
      globals.realtimeStationData = _list11;

      print("realtimeStationData ${globals.realtimeStationData.length} Values");

      setState(() {
        str1 = "Station Status Data Received...";
      }); //
      return 'Number of Realtime Station Data Values: ${globals.realtimeStationData.length}';
    } else {
      throw Exception('Failed to load stations from realtime API');
      //str1 = "Failed to Load Station Status...";
    }
  }

  //THIRD ASYNC
  Future<String> thirdAsync() async {
    print("thirdAsync");

    setState(() {
      str1 = "Calculating Best Routes...";
    }); //

    setState(() {
      str1 = "Getting Current Location...";
    }); //

    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var latM = position.latitude;
    var lonM = position.longitude;
    globals.lastLat = latM;
    globals.lastLon = lonM;

    for (var rt in globals.realtimeStationData) {
      var sid = rt["station_id"].toString();
      var ba = rt["num_bikes_available"].toString();
      var da = rt["num_docks_available"].toString();

      var matchedName =
          globals.stationInfo.where((sta) => sta['station_id'] == sid);
      var na = matchedName.elementAt(0)['name'].toString();
      var lat = matchedName.elementAt(0)['lat'].toString();
      var lon = matchedName.elementAt(0)['lon'].toString();

      //NEXT, GET THIS FOR EACH AND ADD TO COMBINED LIST
      var distanceToMe = await Geolocator()
          .distanceBetween(latM, lonM, double.parse(lat), double.parse(lon));

      var arr = [
        int.parse(sid),
        int.parse(ba),
        int.parse(da),
        na.toString(),
        double.parse(lat),
        double.parse(lon),
        distanceToMe
      ];
      globals.stationsNearMe.add(arr);
    }

    print('Completed, created globals.stationsNearMe');
    print('Length of stationsNearMe: ' +
        globals.stationsNearMe.length.toString());
    //THEN CREATE LIST SORTED BY NEED

    globals.stationsNearMe.sort((a, b) => a[6].compareTo(b[6]));
//    print('Length of (Sorted) stationsNearMe: ' +
//        globals.stationsNearMe.length.toString());

//STATIONS NEAREST TO ME NOW
    globals.theStationsNearMe = globals.stationsNearMe.take(50).toList();

    print('Stations nearest to me, ordered');
    print('${globals.theStationsNearMe.toString()}');


// STATIONS WITH 12+ BIKES
    print('Stations, with 12+ bikes,  nearest to me, ordered');
    for (var cmb2 in globals.stationsNearMe) {
      if (cmb2[1] > 11) {
        globals.theStationsNearMeWith12Bikes.add(cmb2);
      }
      if (globals.theStationsNearMeWith12Bikes.length == 20) {
        print('${globals.theStationsNearMeWith12Bikes.toString()}');
        break;
      }
    }

// TEN STATIONS WITH 12+ DOCKS
    print('Stations, with 12+ docks,  nearest to me, ordered');
    for (var cmb3 in globals.stationsNearMe) {
      if (cmb3[2] > 11) {
        globals.theStationsNearMeWith12Docks.add(cmb3);
//        print(cmb3.toString());
      }
      if (globals.theStationsNearMeWith12Docks.length == 20) {
        print('${globals.theStationsNearMeWith12Docks.toString()}');
        break;
      }
    }

//  TEN BEST ROUTES (SHORTEST TOTAL DISTANCE TO GET 10 AND DROP TEN)
//    globals.theBestRoutes =
    print('Finding 10 best routes, pickup and dropoff');

    List bestRoutes = [];
    String staName = "";
    double distToBikes = 0;
    double distToDocks = 0;
    double distForRoute = 0;
    globals.theBestRoutes = [];

    for (var best1 in globals.theStationsNearMeWith12Bikes) {
      //this station has 12+ bikes
      staName = best1[3];
      distToBikes = best1[6];

      //calc the dist to all stations with 12+ docks
      for (var best2 in globals.theStationsNearMeWith12Docks) {
        if (best2[3] != best1[3]) {
          distToDocks = await Geolocator()
              .distanceBetween(best2[4], best2[5], best1[4], best1[5]);
          distForRoute = distToDocks + distToBikes;
          bestRoutes.add([
            best1[3],
            best2[3],
            distToBikes,
            distToDocks,
            distForRoute,
            best1[1],
            best2[2]
          ]);
        }
      }
    }

    if (bestRoutes.length > 0) {
      globals.theBestRoutes = bestRoutes;
      globals.theBestRoutes.sort((a, b) => a[4].compareTo(b[4]));
      print('${globals.theBestRoutes.getRange(0, 10).toString()}');
    }


    

    return "Number of Best Routes:  ${globals.theBestRoutes.length.toString()}";
  }
  //END THIRD ASYNC

  void _fabPressed() async {
    print('fabPressed');
    numToShow = 10;

    setState(() {
      str1 = "Starting Data Gathering...";
    }); //

    var f = await firstAsync();
    var s = await secondAsync();
    var t = await thirdAsync();
    print("f: $f");
    print("s: $s");
    print("t: $t");

    setState(() {
      str1 = "Update Complete";
      icon1 = Icon(Icons.check_circle);

      col1 = Column(
        children: _createChildren(),
      );

      col2 = Column(
        children: _createChildrenBikes(),
      );

      col3 = Column(
        children: _createChildrenDocks(),
      );

      col4 = Column(
        children: _createChildrenRoutes(),
      );

    });
  }

  updateClosest() {
    setState(() {
      col1 = Column(
        children: _createChildren(),
      );
    });
  }

  List<Widget> _createChildren() {
    return new List<Widget>.generate(numToShow, (int indx) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(globals.theStationsNearMe[indx][3] +
              " \n(${(globals.theStationsNearMe[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
          Spacer(),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child: Text(globals.theStationsNearMe[indx][1].toString()),
          ),
          const SizedBox(width: 5.0),
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            child: Text(globals.theStationsNearMe[indx][2].toString()),
          ),
        ],
      );
    });
  }


  List<Widget> _createChildrenBikes() {
    return new List<Widget>.generate(numToShow, (int indx) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(globals.theStationsNearMeWith12Bikes[indx][3] +
              " \n(${(globals.theStationsNearMeWith12Bikes[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
          Spacer(),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child: Text(globals.theStationsNearMeWith12Bikes[indx][1].toString()),
          ),
          const SizedBox(width: 5.0),
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            child: Text(globals.theStationsNearMeWith12Bikes[indx][2].toString()),
          ),
        ],
      );
    });
  }

  List<Widget> _createChildrenDocks() {
    return new List<Widget>.generate(numToShow, (int indx) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(globals.theStationsNearMeWith12Docks[indx][3] +
              " \n(${(globals.theStationsNearMeWith12Docks[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
          Spacer(),
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            child: Text(globals.theStationsNearMeWith12Docks[indx][1].toString()),
          ),
          const SizedBox(width: 5.0),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child: Text(globals.theStationsNearMeWith12Docks[indx][2].toString()),
          ),
        ],
      );
    });
  }

  //DEL
//  Column(
//  children: <Widget>[
//  const SizedBox(height: 10.0),
//  Container(
//  color: Colors.blue.withOpacity(.3),
//  child: _buildRowsForBestRoutes(0),
//  ),
//  ],
//  ),
  //DEL


  List<Widget> _createChildrenRoutes() {
    return new List<Widget>.generate(numToShow, (int indx) {
      return Column(children: <Widget>[
        const SizedBox(height: 10.0),
        Container(
          color: Colors.blue.withOpacity(.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              const SizedBox(width: 10.0),
              const SizedBox(height: 95.0),

              Column(
                children: <Widget>[
                  Text('${globals.theBestRoutes[indx][0]}' +
                      "\n  Drop At:\n${globals.theBestRoutes[indx][1]}"
                          "\n(${(globals.theBestRoutes[indx][4] / 1609.344).toStringAsFixed(2)} mi)"),
                ],
              ),
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade800,
                    child: Text(globals.theBestRoutes[indx][5].toString()),
                  ),
                  const SizedBox(width: 30),
                  CircleAvatar(
                    backgroundColor: Colors.green.shade800,
                    child: Text(globals.theBestRoutes[indx][6].toString()),
                  ),
                ],
              ),
              const SizedBox(width: 10.0),
            ],
          ),
        ),


      ],
      );
    });
  }



  int numToShow = 10;
  String str1 = "";
  Column col1 = Column(children: <Widget>[
    Text(''),
  ]);

  Column col2 = Column(children: <Widget>[
    Text(''),
  ]);

  Column col3 = Column(children: <Widget>[
    Text(''),
  ]);

  Column col4 = Column(children: <Widget>[
    Text(''),
  ]);

  Icon icon1 = Icon(Icons.av_timer);

  Widget build(BuildContext context) {
    var orangeTextStyle = TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        //  backgroundColor: Colors.white,
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: IconButton(icon: Icon(Icons.sync), onPressed: _fabPressed),
        ),
        title:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('CitiBike Rebalancer'),
        ]),
//        actions: <Widget>[
//          IconButton(
//            icon: Icon(Icons.search),
//            onPressed: () {
//              print('Click search');
//            },
//          ),
//          IconButton(
//            icon: Icon(Icons.star),
//            onPressed: () {
//              print('Click start');
//            },
//          ),
//        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          const SizedBox(height: 16.0),

          GestureDetector(
            onTap: () {
              print('GD1');
              numToShow += 2;
              updateClosest();
            },
            onLongPress: () {
              print('GD1 LongPress');
              numToShow -= 1;
              updateClosest();
            },
            child: Container(
              color: Colors.blue.withOpacity(.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 50.0),
                  Text(
                    "  Closest Stations to Me",
                    style: orangeTextStyle,
                  ),
                ],
              ),
            ),
          ),

//          Container(
//            color: Colors.blue.withOpacity(.3),
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.start,
//              children: <Widget>[
//                const SizedBox(height: 50.0),
//                Text(
//                  "  Closest Stations to Me",
//                  style: orangeTextStyle,
//                ),
//              ],
//            ),
//          ),
          const SizedBox(height: 5.0),

//          Column(
//              children: <Widget>[
//                const SizedBox(height: 10.0),
//                _buildRowsForStationsNearestToMe(0),
//                _buildRowsForStationsNearestToMe(1),
//                _buildRowsForStationsNearestToMe(2),
//                _buildRowsForStationsNearestToMe(3),
//                _buildRowsForStationsNearestToMe(4),
//                _buildRowsForStationsNearestToMe(5),
//                _buildRowsForStationsNearestToMe(6),
//                _buildRowsForStationsNearestToMe(7),
//                _buildRowsForStationsNearestToMe(8),
//                _buildRowsForStationsNearestToMe(9),
//                const SizedBox(height: 10.0),
//              ],
//            ),

          Container(
            child: col1,
          ),

          const SizedBox(height: 10.0),

          Divider(
            height: 10.0,
            indent: 5.0,
            color: Colors.black87,
          ),

          const SizedBox(height: 10.0),

          Container(
            color: Colors.blue.withOpacity(.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 50.0),
                Text(
                  "  10 + Available Bikes & Near Me",
                  style: orangeTextStyle,
                ),
              ],
            ),
          ),

//          Column(
//            children: <Widget>[
//              const SizedBox(height: 15.0),
//              _buildRowsForStationsWithAvailableBikes(0),
//              _buildRowsForStationsWithAvailableBikes(1),
//              _buildRowsForStationsWithAvailableBikes(2),
//              _buildRowsForStationsWithAvailableBikes(3),
//              _buildRowsForStationsWithAvailableBikes(4),
//              const SizedBox(height: 10.0),
//            ],
//          ),

          const SizedBox(height: 10.0),
          Container(
            child: col2,
          ),
          const SizedBox(height: 15.0),

          Divider(
            height: 10.0,
            indent: 5.0,
            color: Colors.black87,
          ),

          const SizedBox(height: 10.0),

          GestureDetector(
            onTap: () {
              print('GD');
            },
            child: Container(
              color: Colors.blue.withOpacity(.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 50.0),
                  Text(
                    "  10 + Open Docks & Near Me",
                    style: orangeTextStyle,
                  ),
                ],
              ),
            ),
          ),

//          Container(
//            color: Colors.blue.withOpacity(.3),
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.start,
//              children: <Widget>[
//                const SizedBox(height: 50.0),
//                Text(
//                  "  10 + Open Docks & Near Me",
//                  style: orangeTextStyle,
//                ),
//              ],
//            ),
//          ),

//          Column(
//            children: <Widget>[
//              const SizedBox(height: 15.0),
//              _buildRowsForStationsWithAvailableDocks(0),
//              _buildRowsForStationsWithAvailableDocks(1),
//              _buildRowsForStationsWithAvailableDocks(2),
//              _buildRowsForStationsWithAvailableDocks(3),
//              _buildRowsForStationsWithAvailableDocks(4),
//              const SizedBox(height: 10.0),
//            ],
//          ),

          const SizedBox(height: 15.0),
          Container(
            child: col3,
          ),
          const SizedBox(height: 10.0),

          Divider(
            height: 10.0,
            indent: 5.0,
            color: Colors.black87,
          ),

          const SizedBox(height: 10.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Best Rebalancer Routes",
                textAlign: TextAlign.right,
                style: orangeTextStyle,
              ),
            ],
          ),
//          const SizedBox(height: 10.0),

//          Column(
//            children: <Widget>[
//              Column(
//                children: <Widget>[
//                  const SizedBox(height: 10.0),
//                  Container(
//                    color: Colors.blue.withOpacity(.3),
//                    child: _buildRowsForBestRoutes(0),
//                  ),
//                ],
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(1),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(2),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(3),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(4),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(5),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(6),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(7),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(8),
//              ),
//              const SizedBox(height: 10.0),
//              Container(
//                color: Colors.blue.withOpacity(.3),
//                child: _buildRowsForBestRoutes(9),
//              ),
//            ],
//          ),

          const SizedBox(height: 10.0),
          Container(
            child: col4,
          ),

        ],
      ),

      bottomNavigationBar: BottomAppBar(
        elevation: 5.0,
//        color: Colors.blue,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 16.0),
            IconButton(
              icon: icon1,
              onPressed: () {},
              color: Colors.blue,
            ),
//            Spacer(),
            const SizedBox(width: 16.0),
            Text(str1),
//            IconButton(
//              icon: Icon(Icons.message),
//              onPressed: () {},
//            ),
            const SizedBox(width: 16.0),
          ],
        ),
      ),
//      floatingActionButton: MaterialButton(
//        onPressed: _fabPressed,
//        color: Colors.red,
//        child: Icon(Icons.refresh),
//        textColor: Colors.white,
//        minWidth: 0,
//        elevation: 4.0,
//        padding: const EdgeInsets.all(8.0),
//        shape: RoundedRectangleBorder(
//          borderRadius: BorderRadius.circular(10.0),
//        ),
//      ),
//      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Row _buildRowsForStationsWithAvailableBikes(int indx) {
    if (globals.theStationsNearMeWith12Bikes.length < 10) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(""),
          ]);
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(globals.theStationsNearMeWith12Bikes[indx][3] +
              " \n(${(globals.theStationsNearMeWith12Bikes[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
          Spacer(),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child:
                Text(globals.theStationsNearMeWith12Bikes[indx][1].toString()),
          ),
          const SizedBox(width: 5.0),
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            child:
                Text(globals.theStationsNearMeWith12Bikes[indx][2].toString()),
          ),
        ],
      );
    }
  }

  Row _buildRowsForStationsWithAvailableDocks(int indx) {
    if (globals.theStationsNearMeWith12Docks.length < 10) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(""),
          ]);
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(globals.theStationsNearMeWith12Docks[indx][3] +
              " \n(${(globals.theStationsNearMeWith12Docks[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
          Spacer(),
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            child:
                Text(globals.theStationsNearMeWith12Docks[indx][1].toString()),
          ),
          const SizedBox(width: 5.0),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child:
                Text(globals.theStationsNearMeWith12Docks[indx][2].toString()),
          ),
        ],
      );
    }
  }

  //TESTER FUNCTION
//  List<Widget> _createChildren() {
//    return new List<Widget>.generate(15,
//        (int indx) {
//        return Row(
//          mainAxisAlignment: MainAxisAlignment.center,
//          crossAxisAlignment: CrossAxisAlignment.center,
//          children: <Widget>[
//            Text(globals.theStationsNearMe[indx][3] +
//                " \n(${(globals.theStationsNearMe[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
//            Spacer(),
//            CircleAvatar(
//              backgroundColor: Colors.blue.shade800,
//              child: Text(globals.theStationsNearMe[indx][1].toString()),
//            ),
//            const SizedBox(width: 5.0),
//            CircleAvatar(
//              backgroundColor: Colors.green.shade800,
//              child: Text(globals.theStationsNearMe[indx][2].toString()),
//            ),
//          ],
//        );
//
//    });
//  }

  Row _buildRowsForStationsNearestToMe(int indx) {
    if (globals.theStationsNearMe.length < 10) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(""),
          ]);
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
//          const SizedBox(width: 10.0),
          Text(globals.theStationsNearMe[indx][3] +
              " \n(${(globals.theStationsNearMe[indx][6] / 1609.344).toStringAsFixed(2)} mi)"),
          Spacer(),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            child: Text(globals.theStationsNearMe[indx][1].toString()),
          ),
          const SizedBox(width: 5.0),
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            child: Text(globals.theStationsNearMe[indx][2].toString()),
          ),
        ],
      );
    }
  }

  Row _buildRowsForBestRoutes(int indx) {
    if (globals.theBestRoutes.length < 10) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(""),
          ]);
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[

          const SizedBox(width: 10.0),
          const SizedBox(height: 95.0),

          Column(
            children: <Widget>[
              Text('${globals.theBestRoutes[indx][0]}' +
                  "\n  Drop At:\n${globals.theBestRoutes[indx][1]}"
                      "\n(${(globals.theBestRoutes[indx][4] / 1609.344).toStringAsFixed(2)} mi)"),
            ],
          ),
          Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Colors.blue.shade800,
                child: Text(globals.theBestRoutes[indx][5].toString()),
              ),
              const SizedBox(width: 30),
              CircleAvatar(
                backgroundColor: Colors.green.shade800,
                child: Text(globals.theBestRoutes[indx][6].toString()),
              ),
            ],
          ),
          const SizedBox(width: 10.0),
        ],
      );
    }
  }

//  Card _buildRowsForBestRoutes(int indx) {
//    var cardTextStyle = TextStyle(
//      color: Colors.black87,
////      fontWeight: FontWeight.bold,
//      fontSize: 14,
//    );
//
//    if (globals.theBestRoutes.length < 10) {
//      return Card(
//        child: Column(
//          mainAxisSize: MainAxisSize.max,
//          children: <Widget>[
//            const ListTile(
////              leading: Icon(Icons.album, size: 50),
//              title: Text(''),
////              subtitle: Text('TWICE'),
//            ),
//          ],
//        ),
//      );
//    } else {
//      return Card(
//        child: Column(
//          mainAxisSize: MainAxisSize.max,
//          children: <Widget>[
//            ListTile(
//              title: Row(
//                mainAxisAlignment: MainAxisAlignment.center,
//                crossAxisAlignment: CrossAxisAlignment.center,
//                children: <Widget>[
////          const SizedBox(width: 10.0),
//                  Text('${globals.theBestRoutes[indx][0]}' +
//                      "\nto > ${globals.theBestRoutes[indx][1]}"
//                          "\n(${(globals.theBestRoutes[indx][4] / 1609.344).toStringAsFixed(2)} mi)\n",
//                    style: cardTextStyle,
//                  ),
//                  Spacer(),
//                  CircleAvatar(
//                    backgroundColor: Colors.blue.shade800,
//                    child: Text(globals.theBestRoutes[indx][5].toString()),
//                  ),
//                  const SizedBox(width: 5.0),
//                  CircleAvatar(
//                    backgroundColor: Colors.green.shade800,
//                    child: Text(globals.theBestRoutes[indx][6].toString()),
//                  ),
//                ],
//              ),
//
////              leading: Icon(Icons.album, size: 50),
////              trailing: Text(
////                  " (${(globals.theBestRoutes[indx][4] / 1609.344).toStringAsFixed(2)} mi)"),
////              title: Text(
////                '${globals.theBestRoutes[indx][0]}  (${globals.theBestRoutes[indx][5]} B)',
////                style: cardTextStyle,
////              ),
////              subtitle: Text(
////                'to > ${globals.theBestRoutes[indx][1]}  (${globals.theBestRoutes[indx][6]} D)',
////                style: cardTextStyle,
////              ),
//            ),
//            Row(
//              mainAxisAlignment: MainAxisAlignment.center,
//              crossAxisAlignment: CrossAxisAlignment.center,
//              children: <Widget>[
////          const SizedBox(width: 10.0),
//                Text('${globals.theBestRoutes[indx][0]}' +
//                    "\nto > ${globals.theBestRoutes[indx][1]}"
//                        "\n(${(globals.theBestRoutes[indx][4] / 1609.344).toStringAsFixed(2)} mi)\n"),
//                Spacer(),
//                CircleAvatar(
//                  backgroundColor: Colors.blue.shade800,
//                  child: Text(globals.theBestRoutes[indx][5].toString()),
//                ),
//                const SizedBox(width: 15.0),
//                CircleAvatar(
//                  backgroundColor: Colors.green.shade800,
//                  child: Text(globals.theBestRoutes[indx][6].toString()),
//                ),
//              ],
//            ),
//          ],
//        ),
//      );
//    }
//  }

//  Row _buildRecentWikiRow(String avatar, String title) {
//    return Row(
//      children: <Widget>[
//        CircleAvatar(
//          radius: 15.0,
////          backgroundImage: CachedNetworkImageProvider(avatar),
//        ),
//        const SizedBox(width: 10.0),
//        Text(
//          title,
//          style: TextStyle(
//            color: Colors.grey.shade700,
//            fontWeight: FontWeight.bold,
//          ),
//        )
//      ],
//    );
//  }

//  Stack _buildWikiCategory(String label, Color color) {
//    return Stack(
//      children: <Widget>[
//        Container(
//          padding: const EdgeInsets.all(26.0),
//          alignment: Alignment.centerRight,
//          child: Opacity(
//              opacity: 0.3,
//              child: Icon(
//                Icons.add,
//                size: 40,
//                color: Colors.white,
//              )),
//          decoration: BoxDecoration(
//            color: color,
//            borderRadius: BorderRadius.circular(20.0),
//          ),
//        ),
//        Padding(
//          padding: const EdgeInsets.all(16.0),
//          child: Column(
//            crossAxisAlignment: CrossAxisAlignment.start,
//            mainAxisAlignment: MainAxisAlignment.center,
//            children: <Widget>[
//              Icon(
//                Icons.add,
//                color: Colors.white,
//              ),
//              const SizedBox(height: 16.0),
//              Text(
//                label,
//                style: TextStyle(
//                  color: Colors.white,
//                  fontWeight: FontWeight.bold,
//                ),
//              )
//            ],
//          ),
//        )
//      ],
//    );
//  }

}

class Station {
  final int stationId;
  final String name;
  final String lat;
  final String lon;
  final int isSelected;

  static List<Station> los = [];

  Station({this.stationId, this.name, this.lat, this.lon, this.isSelected});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationId: json['station_id'],
      name: json['name'],
      lat: json['lat'],
      lon: json['lon'],
    );
  }

  Map<String, dynamic> toJson() => _stationToJson(this);

  //creates a single json represented object
  Map<String, dynamic> _stationToJson(Station instance) {
    return <String, dynamic>{
      'station_id': instance.stationId,
      'name': instance.name,
      'lat': instance.lat,
      'lon': instance.lon,
    };
  }

  //this is my new json object
  final myNewJson = new StationList(los);
}

class StationList {
  final List<Station> stations;

  StationList(this.stations);

  StationList.fromJson(Map<String, dynamic> json)
      : stations = json['stations'] != null
            ? List<Station>.from(json['stations'])
            : null;

  Map<String, dynamic> toJson() => {
        'stations': stations,
      };
}

class Selections {
  static List selections = [];
}
