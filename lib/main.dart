import 'package:flutter/material.dart';
import 'favorites.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MaterialApp(
    title: 'Navigation Basics',
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //false: currently the current city isn't in favorites list
  TextEditingController _controllerSearch = new TextEditingController();
  String _codeCurrentCity = "";
  String _currentCity = "";
  double _temperatureCurrentCity = 0.0;
  String _weatherNowCurrentCity = "Scattered clouds";
  String _whichDayIsIt = "";
  List<String> _nameDays = ["", "", "", "", ""];
  List<double> _temperatureMaximum = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> _temperatureMinimum = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> _weatherInText = ["", "", "", "", ""];
  String _signDegrees = "\u00B0";
  String _signCelsiusOrFahrenheit = " C";
  List<String> _listFavoriteCities = [];
  List<String> _listCodeFavoriteCities = [];
  bool _isFavouriteCitiesListPopulated = false;
  bool _isCurrentCityWeatherPopulated = false;
  bool _isCurrentCityForecastPopulated = false;
  List<String> _searchSuggestions = [];
  String _selectedProductInSearch = "";
  List<String> _suggestedSearchCityCode = [];
  List<String> _suggestedSearchCityName = [];
  List<String> _suggestedSearchAdministrativeArea = [];
  List<String> _suggestedSearchCountryName = [];
  bool _isThemeDark = true;
  bool _isTemperatureFahrenheit = false;
  ThemeData _darkTheme = ThemeData(
    accentColor: Colors.red,
    brightness: Brightness.dark,
    primaryColor: Colors.amber,
  );
  ThemeData _lightTheme = ThemeData(
      accentColor: Colors.pink,
      brightness: Brightness.light,
      primaryColor: Colors.blue);
  Position _currentPosition;
  String _currentAddress;
  bool isSwitched = false;

  //if the user wishes to view the temperature in Fahrenheit
  _convertCelsiusToFahrenheit(double temperature) {
    return (temperature * 1.8 + 32).roundToDouble();
  }

  //find the weather where the app's user is located right now.
  //If you can't find the geolocation ofthe user, use Tel Aviv a default location
  _getWeatherUserLocation() async {
    Response response;
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double latitude = position.latitude;
      double longitude = position.longitude;

      response = await Dio().get(
          "http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=wKWhAUta6WlNqMEAkQUXDCy6G6cPjnKp&q=$latitude,$longitude");

      _codeCurrentCity = response.data["Key"].toString();
      _currentCity = response.data["LocalizedName"].toString();
      if (_codeCurrentCity.length == 0) _codeCurrentCity = "213181";
      if (_currentCity.length == 0) _currentCity = "Tel Aviv";
      _populateFavoriteCitiesList();
    } catch (e) {
      if (_codeCurrentCity.length == 0) _codeCurrentCity = "213181";
      if (_currentCity.length == 0) _currentCity = "Tel Aviv";
      _populateFavoriteCitiesList();
    }
  }

  //Search box: look for cities suitable to the entered string
  _searchCityName() async {
    var dio = Dio();
    Response response;

    try {
      if (_controllerSearch.value.text.length < 3) return;
      response = await Dio().get(
          "http://dataservice.accuweather.com/locations/v1/cities/autocomplete?apikey=wKWhAUta6WlNqMEAkQUXDCy6G6cPjnKp&q=" +
              _controllerSearch.value.text);

      for (int i = 0; i < 20; i++) {
        try {
          _suggestedSearchCityCode.add(response.data[i]["Key"]);
          _suggestedSearchCityName.add(response.data[i]["LocalizedName"]);
          _suggestedSearchAdministrativeArea
              .add(response.data[i]["AdministrativeArea"]["LocalizedName"]);
          _suggestedSearchCountryName
              .add(response.data[i]["Country"]["LocalizedName"]);
        } catch (e) {}
      }
    } catch (e) {}
  }

  //calculates what day of the week will it be in x days
  String _daysCalculator(int numDays) {
    int temp = 0;
    var now = new DateTime.now();
    int day = now.weekday;
    temp = day;

    for (int h = 0; h < numDays; h++) {
      if (temp + 1 == 8)
        temp = 1;
      else
        temp = temp + 1;
    }

    day = temp;

    if (day == 7)
      _whichDayIsIt = "Sun";
    else if (day == 1)
      _whichDayIsIt = "Mon";
    else if (day == 2)
      _whichDayIsIt = "Tue";
    else if (day == 3)
      _whichDayIsIt = "Wed";
    else if (day == 4)
      _whichDayIsIt = "Thu";
    else if (day == 5)
      _whichDayIsIt = "Fri";
    else if (day == 6) _whichDayIsIt = "Sat";
  }

  //we need to retrieve a 5-day forcast for the current city
  _getCurrentCityForecast() async {
    var dio = Dio();
    Response response;

    try {
      response = await Dio().get(
          "http://dataservice.accuweather.com/forecasts/v1/daily/5day/" +
              _codeCurrentCity +
              "?apikey=wKWhAUta6WlNqMEAkQUXDCy6G6cPjnKp&details=true&metric=true");

      for (int i = 0; i < 5; i++) {
        _daysCalculator(i);
        _nameDays[i] = _whichDayIsIt;
        double d = response.data["DailyForecasts"][i]["Temperature"]["Maximum"]
            ["Value"];

        if (_isTemperatureFahrenheit == true) {
          d = _convertCelsiusToFahrenheit(d);
          d = d.roundToDouble();
        }
        _temperatureMaximum[i] = d;

        double f = response.data["DailyForecasts"][i]["Temperature"]["Minimum"]
            ["Value"];
        if (_isTemperatureFahrenheit == true) {
          f = _convertCelsiusToFahrenheit(f);
          f = f.roundToDouble();
        }
        _temperatureMinimum[i] = f;
        String temp = response.data["DailyForecasts"][i]['Day']['IconPhrase'];
        int numSpaces = 0;
        String t = "";
        for (int h = 0; h < temp.length; h++) {
          if (temp[h] != " ")
            t += temp[h];
          else {
            numSpaces++;
            t += " ";
            if (numSpaces > 1) break;
          }
        }
        _weatherInText[i] = t;
      }
    } catch (e) {
      final scaffold = Scaffold.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content:
              const Text('Sorry but can\'t show 5-day forecast right now!'),
        ),
      );
    }
  }

  //we need to retrieve from Geolocation API the current city's weather conditions
  _getCityCurrentWeather() async {
    var dio = Dio();
    Response response;

    try {
      response = await Dio().get(
          "http://dataservice.accuweather.com/currentconditions/v1/" +
              _codeCurrentCity +
              "?apikey=wKWhAUta6WlNqMEAkQUXDCy6G6cPjnKp");

      _weatherNowCurrentCity = response.data[0]["WeatherText"];

      _temperatureCurrentCity =
          response.data[0]["Temperature"]["Metric"]["Value"];
    } catch (e) {
      final scaffold = Scaffold.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Sorry but can\'t show weather data now!'),
        ),
      );
    }
  }

  // if the user wishes to add the current city to the Favorite list
  void _addCityToFavorites() async {
    if (!_listCodeFavoriteCities.contains(_codeCurrentCity)) {
      _listCodeFavoriteCities.add(_codeCurrentCity);
    }
    if (!_listFavoriteCities.contains(_currentCity)) {
      _listFavoriteCities.add(_currentCity);
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("codeFavoriteCities", _listCodeFavoriteCities);
    prefs.setStringList("favoriteCities", _listFavoriteCities);
    setState(() {});
  }

  // if the user wishes to remove the current city from the Favorite list
  void _removeCityFromFavorites() async {
    _listCodeFavoriteCities.remove(_codeCurrentCity);
    _listFavoriteCities.remove(_currentCity);
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("codeFavoriteCities", _listCodeFavoriteCities);
    prefs.setStringList("favoriteCities", _listFavoriteCities);
    setState(() {});
  }

  //read the Favorite cities list into local variables
  _populateFavoriteCitiesList() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _listCodeFavoriteCities = prefs.getStringList("codeFavoriteCities");
      _listFavoriteCities = prefs.getStringList("favoriteCities");
      (prefs.getBool("isThemeDark") == true ||
              prefs.getBool("isThemeDark") == false)
          ? _isThemeDark = prefs.getBool("isThemeDark")
          : _isThemeDark = false;
      (prefs.getBool("isTemperatureFahrenheit") == true ||
              prefs.getBool("isTemperatureFahrenheit") == false)
          ? _isTemperatureFahrenheit = prefs.getBool("isTemperatureFahrenheit")
          : _isTemperatureFahrenheit = false;

      if (_listFavoriteCities == [] || _listFavoriteCities == null)
        _listFavoriteCities = [];
      if (_listCodeFavoriteCities == [] || _listCodeFavoriteCities == null)
        _listCodeFavoriteCities = [];
      //Need to wait till the whether of the current city is retrieved
      await _getCityCurrentWeather();
      //Need to wait till the 5-day forecast for the current city is retrieved
      await _getCurrentCityForecast();

      setState(() {
        _isFavouriteCitiesListPopulated = true;
        _isCurrentCityWeatherPopulated = true;
        _isCurrentCityForecastPopulated = true;
      });
    } catch (e) {
      print("eeeeeeeeeeeeeeeee");
      _listFavoriteCities = [];
      _listCodeFavoriteCities = [];
      final scaffold = Scaffold.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: const Text(
              'Sorry but can\'t work with favorite cities right now!'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getWeatherUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFavouriteCitiesListPopulated == false ||
        _isCurrentCityWeatherPopulated == false ||
        _isCurrentCityForecastPopulated == false) return Container();

    return MaterialApp(
        title: 'Weather',
        theme: _isThemeDark == false ? _lightTheme : _darkTheme,
        home: Scaffold(
          appBar: AppBar(
            title: Text("Weather"),
            actions: <Widget>[
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: Colors.yellow,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      bool res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Favorites()),
                      );
                      if (res == true) {
                        final prefs = await SharedPreferences.getInstance();
                        _codeCurrentCity =
                            prefs.getString("codeSelectedFavoriteCity");
                        _currentCity = prefs.getString("selectedFavoriteCity");
                        _populateFavoriteCitiesList();
                      }
                    },
                  ),
                  SizedBox(width: 30.0),
                  Row(
                    children: [
                      Text("Bright"),
                      Switch(
                          value: _isThemeDark,
                          onChanged: (toggle) async {
                            final prefs = await SharedPreferences.getInstance();

                            prefs.setBool("isThemeDark", toggle);
                            setState(() {
                              _isThemeDark = toggle;
                            });
                          }),
                      Text("Dark"),
                    ],
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              //Search Bar
              Padding(
                padding:
                    const EdgeInsets.only(left: 40.0, right: 40.0, top: 20.0),
                child: Container(
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: new BorderRadius.all(
                          new Radius.circular(15.0),
                        ),
                      ),
                      child: TextField(
                        controller: _controllerSearch,
                        style: TextStyle(
                            color: _isThemeDark == true
                                ? Colors.blue
                                : Colors.grey),
                        onChanged: (text) async {
                          //everytime the user starts entering a search, we need to clean the existing serach suggestions
                          if (_controllerSearch.value.text.length == 1) {
                            _suggestedSearchAdministrativeArea = [];
                            _suggestedSearchCityCode = [];
                            _suggestedSearchCountryName = [];
                            _suggestedSearchCityName = [];
                          }
                          await _searchCityName();
                          setState(() {
                            _searchSuggestions = [];
                            for (int i = 0; i < 20; i++) {
                              try {
                                _searchSuggestions.add(
                                    _suggestedSearchCityName[i] +
                                        "," +
                                        _suggestedSearchAdministrativeArea[i] +
                                        "," +
                                        _suggestedSearchCountryName[i]);
                              } catch (e) {}
                            }
                          });
                        },
                        decoration: new InputDecoration(
                          prefixIcon: new Icon(Icons.search,
                              color: _isThemeDark == true
                                  ? Colors.blue
                                  : Colors.grey),
                          hintText: "Look for cities..",
                          enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    )),
              ),

              //Row with the current temperature  & Add to Favorites
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(10.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(width: 2),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: _listFavoriteCities
                                                .contains(_currentCity) ==
                                            true
                                        ? Colors.pink
                                        : Colors.grey,
                                    size: 40.0,
                                    //semanticLabel: 'Add to Favorites',
                                  ),
                                  new RaisedButton(
                                    padding: const EdgeInsets.all(8.0),
                                    textColor: Colors.white,
                                    color: _listCodeFavoriteCities
                                                .contains(_codeCurrentCity) ==
                                            true
                                        ? Colors.grey
                                        : Colors.pink,
                                    onPressed: _listCodeFavoriteCities
                                                .contains(_codeCurrentCity) ==
                                            false
                                        ? _addCityToFavorites
                                        : _removeCityFromFavorites,
                                    child: _listCodeFavoriteCities
                                                .contains(_codeCurrentCity) ==
                                            true
                                        ? new Text("Remove from Favorites")
                                        : new Text("Add to Favorites"),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.beach_access,
                                    color: Colors.blue,
                                    size: 40.0,
                                  ),
                                  _isTemperatureFahrenheit == false
                                      ? Text("$_currentCity\n " +
                                          _temperatureCurrentCity.toString() +
                                          "\u00B0 C")
                                      : Text("$_currentCity\n " +
                                          _convertCelsiusToFahrenheit(
                                                  _temperatureCurrentCity)
                                              .toString() +
                                          "\u00B0 F"),
                                ],
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _weatherNowCurrentCity,
                                style: TextStyle(fontSize: 28),
                              ),
                              Text("C" + "\u00B0"),
                              Container(
                                child: Switch(
                                    value: _isTemperatureFahrenheit,
                                    onChanged: (toggle) async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      prefs.setBool(
                                          "isTemperatureFahrenheit", toggle);
                                      _isTemperatureFahrenheit = toggle;
                                      toggle == false
                                          ? _signCelsiusOrFahrenheit = " C"
                                          : _signCelsiusOrFahrenheit = " F";
                                      //_getWeatherUserLocation();
                                      _populateFavoriteCitiesList();
                                      //_getCurrentCityForecast();
                                    }),
                              ),
                              Text("F" + "\u00B0"),
                            ],
                          ),

                          //showing the forecast for the next 5 days
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 100,
                                width: 150,
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 1,
                                        color: _isThemeDark == true
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _nameDays[0] +
                                            "\n Max:" +
                                            _temperatureMaximum[0].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n Min:" +
                                            _temperatureMinimum[0].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n" +
                                            _weatherInText[0],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    )),
                              ),
                              SizedBox(
                                height: 100,
                                width: 150,
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 1,
                                        color: _isThemeDark == true
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _nameDays[1] +
                                            "\n Max:" +
                                            _temperatureMaximum[1].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n Min:" +
                                            _temperatureMinimum[1].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n" +
                                            _weatherInText[1],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    )),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 100,
                                width: 150,
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 1,
                                        color: _isThemeDark == true
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _nameDays[2] +
                                            "\n Max:" +
                                            _temperatureMaximum[2].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n Min:" +
                                            _temperatureMinimum[2].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n" +
                                            _weatherInText[2],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    )),
                              ),
                              SizedBox(
                                height: 100,
                                width: 150,
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 1,
                                        color: _isThemeDark == true
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _nameDays[3] +
                                            "\n Max:" +
                                            _temperatureMaximum[3].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n Min:" +
                                            _temperatureMinimum[3].toString() +
                                            _signDegrees +
                                            _signCelsiusOrFahrenheit +
                                            "\n" +
                                            _weatherInText[3],
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    )),
                              ),
                            ],
                          ),

                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 100,
                                  width: 150,
                                  child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1,
                                          color: _isThemeDark == true
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _nameDays[4] +
                                              "\n Max:" +
                                              _temperatureMaximum[4]
                                                  .toString() +
                                              _signCelsiusOrFahrenheit +
                                              _signDegrees +
                                              "\n Min:" +
                                              _temperatureMinimum[4]
                                                  .toString() +
                                              _signDegrees +
                                              _signCelsiusOrFahrenheit +
                                              "\n" +
                                              _weatherInText[4],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      )),
                                ),
                              ]),
                        ],
                      ),
                      Column(children: [
                        if (_searchSuggestions.length > 0) ...[
                          RaisedButton(
                            onPressed: () {
                              setState(() {
                                _controllerSearch.text = "";
                                _searchSuggestions = [];
                              });
                            },
                            textColor: Colors.white,
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF0D47A1),
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(10.0),
                              child: const Text('Clean',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                        if (_searchSuggestions.length > 0) ...[
                          Material(
                            elevation: 20,
                            child: Container(
                                height: 200,
                                //width: 200,
                                child: new ListView.builder(
                                    //scrollDirection: Axis.horizontal,
                                    itemCount: _searchSuggestions.length,
                                    itemBuilder:
                                        (BuildContext ctxt, int index) {
                                      return GestureDetector(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 10.0),
                                          child: new Text(
                                            _searchSuggestions[index],
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey),
                                          ),
                                        ),
                                        onTap: (() {
                                          _selectedProductInSearch =
                                              _searchSuggestions[index];
                                          _codeCurrentCity =
                                              _suggestedSearchCityCode[index];

                                          _currentCity =
                                              _suggestedSearchCityName[index];
                                          _populateFavoriteCitiesList();
                                          _controllerSearch.text =
                                              _selectedProductInSearch;
                                          _searchSuggestions = [];

                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            _controllerSearch.text = "";
                                          });
                                        }),
                                      );
                                    })),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
