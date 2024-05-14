import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Region {
  final String name;
  final List<Country> countries;

  Region({required this.name, required this.countries});
}

class Country {
  final String name;
  final String flagUrl;
  final String region;
  final String subRegion;
  final int population;
  final List<String> languages;
  final List<String> currencies;

  Country({
    required this.name,
    required this.flagUrl,
    required this.region,
    required this.subRegion,
    required this.population,
    required this.languages,
    required this.currencies,
  });
}

class CountryFlagScreen extends StatefulWidget {
  @override
  _CountryFlagScreenState createState() => _CountryFlagScreenState();
}

class _CountryFlagScreenState extends State<CountryFlagScreen> {
  late List<Region> regions = [];
  late List<Country> allCountries = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchRegions();
  }

  void fetchRegions() async {
    final response = await http.get(Uri.parse('https://restcountries.com/v3.1/all'));
    final List<dynamic> data = json.decode(response.body);
    final Map<String, List<Country>> countriesByRegion = {};

    data.forEach((countryData) {
      final String regionName = countryData['region'] ?? 'Unknown';
      final String countryName = countryData['name']['common'];
      final String flagUrl = countryData['flags']['png'];
      final String subRegion = countryData['subregion'] ?? 'Unknown';
      final int population = countryData['population'] ?? 0;

      final Map<dynamic, dynamic>? languagesData = countryData['languages'];
      List<String> languages = [];
      if (languagesData != null) {
        languagesData.values.forEach((value) {
          languages.add(value.toString());
        });
      }

      dynamic currenciesData = countryData['currencies'];
      List<String> currencies = [];
      if (currenciesData is List<dynamic>) {
        currenciesData.forEach((currency) {
          currencies.add(currency['name'].toString());
        });
      } else if (currenciesData is Map<String, dynamic>) {
        currenciesData.values.forEach((value) {
          currencies.add(value['name'].toString());
        });
      }

      countriesByRegion.putIfAbsent(regionName, () => []);
      countriesByRegion[regionName]!.add(Country(
        name: countryName,
        flagUrl: flagUrl,
        region: regionName,
        subRegion: subRegion,
        population: population,
        languages: languages,
        currencies: currencies,
      ));
      allCountries.add(Country(
        name: countryName,
        flagUrl: flagUrl,
        region: regionName,
        subRegion: subRegion,
        population: population,
        languages: languages,
        currencies: currencies,
      ));
    });

    final List<Region> regionsList = countriesByRegion.entries.map((entry) {
      return Region(name: entry.key, countries: entry.value);
    }).toList();

    setState(() {
      regions = regionsList;
    });
  }

  void sortByName() {
    regions.forEach((region) {
      region.countries.sort((a, b) => a.name.compareTo(b.name));
    });
    setState(() {});
  }

  void sortByPopulation() {
    regions.forEach((region) {
      region.countries.sort((a, b) => b.population.compareTo(a.population));
    });
    setState(() {});
  }

  List<Country> get filteredCountries {
    return allCountries.where((country) {
      final nameLower = country.name.toLowerCase();
      final searchTextLower = searchText.toLowerCase();
      return nameLower.contains(searchTextLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Country Flags'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: CountrySearch(allCountries));
            },
          ),
          IconButton(
            icon: Icon(Icons.sort_by_alpha),
            onPressed: sortByName,
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: sortByPopulation,
          ),
        ],
      ),
      body: regions.isNotEmpty
          ? ListView.builder(
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final region = regions[index];
                return ExpansionTile(
                  title: Text(region.name),
                  children: region.countries
                      .map((country) => ListTile(
                            leading: Image.network(
                              country.flagUrl,
                              width: 50,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                            title: Text('${country.name} - Population: ${country.population}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CountryDetailScreen(country)),
                              );
                            },
                          ))
                      .toList(),
                );
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class CountryDetailScreen extends StatelessWidget {
  final Country country;

  CountryDetailScreen(this.country);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(country.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              country.flagUrl,
              width: 200,
              height: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            Text('Region: ${country.region}'),
            Text('Subregion: ${country.subRegion}'),
            Text('Population: ${country.population}'),
            SizedBox(height: 16),
            Text('Languages:'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: country.languages.map((lang) => Text('- $lang')).toList(),
            ),
            SizedBox(height: 16),
            Text('Currencies:'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: country.currencies.map((currency) => Text('- $currency')).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class CountrySearch extends SearchDelegate<String> {
  final List<Country> countries;

  CountrySearch(this.countries);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchResults = query.isEmpty
        ? countries
        : countries.where((country) => country.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final country = searchResults[index];
        return ListTile(
          title: Text(country.name),
          onTap: () {
            close(context, country.name);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CountryDetailScreen(country)),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final searchResults = query.isEmpty
        ? countries
        : countries.where((country) => country.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final country = searchResults[index];
        return ListTile(
          title: Text(country.name),
          onTap: () {
            close(context, country.name);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CountryDetailScreen(country)),
            );
          },
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CountryFlagScreen(),
  ));
}
