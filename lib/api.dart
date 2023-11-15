import 'dart:convert';
import 'package:http/http.dart' as http;

String apiKey = '74bf7016305804c5120589f147dbf94a';

class GeocodingResult {
  final double latitude;
  final double longitude;

  GeocodingResult(this.latitude, this.longitude);
}

class Forecast {
  final String date;
  final double temperatureKelvin;
  final String weatherCondition;
  final double humidity;

  Forecast(
      this.date, this.temperatureKelvin, this.weatherCondition, this.humidity);

  double get temperatureCelsius => temperatureKelvin - 273.15;
}

class AirQuality {
  final int index;
  final Map<String, double> components;

  AirQuality(this.index, this.components);
}

Future<GeocodingResult> getGeocoding(String cidade) async {
  String url =
      'https://api.openweathermap.org/geo/1.0/direct?q=$cidade&limit=1&appid=$apiKey';
  try {
    final response = await http.get(Uri.parse(url));
    // se status do http retornar 200 (Ok)
    if (response.statusCode == 200) {
      // decodificar o JSON e retornar os dados
      List<Map<String, dynamic>> result =
          List<Map<String, dynamic>>.from(json.decode(response.body));
      if (result.isNotEmpty) {
        // extrai lat e lon do primeiro resultado
        double latitude = result[0]['lat'];
        double longitude = result[0]['lon'];

        return GeocodingResult(latitude, longitude);
      }
    } else {
      // se a resposta não for bem-sucedida, lançar uma excecção
      throw Exception(
          'Falha ao obter dados de geocoding. Código de status: ${response.statusCode}');
    }
  } catch (e) {
    // tratar erros de rede ou exceções gerais
    throw Exception('Erro durante a chamada da API de geocoding: $e');
  }

  return GeocodingResult(0.0, 0.0);
}

Future<List<Forecast>> getForecast(double latitude, double longitude) async {
  try {
    String url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<Forecast> forecasts = [];

      Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData.containsKey('list') && jsonData['list'] is List) {
        List<dynamic> forecastDataList = jsonData['list'];

        // mapear as previsões agrupadas por data
        Map<String, dynamic> groupedForecasts = {};
        for (var forecastData in forecastDataList) {
          String date = forecastData['dt_txt'].toString().split(' ')[0];
          if (groupedForecasts.containsKey(date)) {
            groupedForecasts[date].add(forecastData);
          } else {
            groupedForecasts[date] = [forecastData];
          }
        }

        // limitar para os últimos 5 dias e adicionar à lista final
        groupedForecasts.forEach((date, forecastsOnDate) {
          if (forecasts.length < 5 &&
              forecastsOnDate != null &&
              forecastsOnDate.isNotEmpty) {
            forecasts.add(Forecast(
              date,
              forecastsOnDate[0]['main']['temp'],
              forecastsOnDate[0]['weather'][0]['main'],
              forecastsOnDate[0]['main']['humidity'],
            ));
          }
        });
      } else {
        throw Exception(
            'Falha ao obter dados de previsão. Código de status: ${response.statusCode}');
      }

      return forecasts;
    }
  } catch (e) {
    throw Exception('Erro durante a chamada da API de previsão: $e');
  }

  return [];
}

Future<AirQuality> getAirQuality(double latitude, double longitude) async {
  try {
    String url =
        'http://api.openweathermap.org/data/2.5/air_pollution?lat=$latitude&lon=$longitude&appid=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData.containsKey('list') && jsonData['list'] is List) {
        var airQualityData = jsonData['list'][0];
        int airQualityIndex = airQualityData['main']['aqi'];

        Map<String, double> components = {};
        if (airQualityData.containsKey('components')) {
          Map<String, dynamic> componentsData = airQualityData['components'];
          componentsData.forEach((key, value) {
            components[key] = value.toDouble();
          });
        }

        return AirQuality(airQualityIndex, components);
      }
    }

    throw Exception(
        'Falha ao obter dados de qualidade do ar. Código de status: ${response.statusCode}');
  } catch (e) {
    throw Exception('Erro durante a chamada da API de qualidade do ar: $e');
  }
}
