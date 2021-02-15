import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class Favorites extends StatefulWidget {
  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  List<String> _listCodeFavoriteCities = [];
  List<String> _listFavoriteCities = [];
  List<double> _listFavoriteCitiesTemperature = [];
  List<String> _listFavoriteCitiesWeather = [];
  String _signDegrees = "\u00B0";
  String _signCelsiusOrFahrenheit = " C";
  bool _isFavouriteCitiesListPopulated = false;
  bool _isTemperatureFahrenheit = false;
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isThemeDark = true;
  ThemeData _darkTheme = ThemeData(
    accentColor: Colors.red,
    brightness: Brightness.dark,
    primaryColor: Colors.amber,
  );

  ThemeData _lightTheme = ThemeData(
      accentColor: Colors.pink,
      brightness: Brightness.light,
      primaryColor: Colors.blue);

  //if the user wishes to view the temperature in Fahrenheit
  _convertCelsiusToFahrenheit(double temperature) {
    if (_isTemperatureFahrenheit == false)
      return temperature;
    else
      return (temperature * 1.8 + 32).roundToDouble();
  }

  //we need to know what are the cities in the Favorites list
  _populateFavoriteCitiesList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _listCodeFavoriteCities = prefs.getStringList("codeFavoriteCities");
      _listFavoriteCities = prefs.getStringList("favoriteCities");
      prefs.setString("codeSelectedFavoriteCity", "213181");
      prefs.setString("selectedFavoriteCity", "Tel Aviv");
      _isThemeDark = prefs.getBool("isThemeDark");
      _isTemperatureFahrenheit = prefs.getBool("isTemperatureFahrenheit");
      _isTemperatureFahrenheit == false
          ? _signCelsiusOrFahrenheit = " C"
          : _signCelsiusOrFahrenheit = " F";

      if (_listCodeFavoriteCities.toString() == "null")
        _listCodeFavoriteCities = [];
      //for each favorite city, we need to know the conditions at this moment
      await _getCityCurrentWeather();
    } catch (e) {
      _listCodeFavoriteCities = [];
      final scaffold = Scaffold.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('No favorite cities yet...'),
        ),
      );
    }

    setState(() {
      _isFavouriteCitiesListPopulated = true;
    });
  }

  //going over the favorite cities  and getting their temperature & weather conditions
  _getCityCurrentWeather() async {
    var dio = Dio();
    Response response;

    try {
      for (int i = 0; i < _listCodeFavoriteCities.length; i++) {
        response = await Dio().get(
            "http://dataservice.accuweather.com/currentconditions/v1/" +
                _listCodeFavoriteCities[i] +
                "?apikey=wKWhAUta6WlNqMEAkQUXDCy6G6cPjnKp");

        _listFavoriteCitiesWeather.add(response.data[0]["WeatherText"]);

        _listFavoriteCitiesTemperature
            .add(response.data[0]["Temperature"]["Metric"]["Value"]);
      }
    } catch (e) {
      final scaffold = Scaffold.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Sorry but can\'t show weather data now!'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _populateFavoriteCitiesList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFavouriteCitiesListPopulated == false) return Container();

    return MaterialApp(
      theme: _isThemeDark == false ? _lightTheme : _darkTheme,
      home: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text("Favorites"),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              )
            ],
          ),
          body: GridView.count(
            // crossAxisCount is the number of columns
            crossAxisCount: 2,

            children: List.generate(_listCodeFavoriteCities.length, (index) {
              return GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setString("codeSelectedFavoriteCity",
                      _listCodeFavoriteCities[index]);
                  prefs.setString(
                      "selectedFavoriteCity", _listFavoriteCities[index]);
                  Navigator.pop(context, true);
                },
                child: Container(
                  margin: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: _isThemeDark == true ? Colors.white : Colors.black,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _listFavoriteCities[index] +
                          "\n" +
                          _convertCelsiusToFahrenheit(
                                  _listFavoriteCitiesTemperature[index])
                              .toString() +
                          _signDegrees +
                          _signCelsiusOrFahrenheit +
                          "\n" +
                          _listFavoriteCitiesWeather[index],
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            }),
          )),
    );
  }
}
