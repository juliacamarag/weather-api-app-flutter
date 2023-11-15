import 'api.dart';
import 'package:flutter/material.dart';

void main() async {
  String cidade = 'New York';
  buscarDados(cidade);
}

Future<void> buscarDados(String cidade) async {
  try {
    Map<String, double> coordenadas = await obterCoordenadas(cidade);

    double latitude = coordenadas['latitude'] ?? 0.0;
    double longitude = coordenadas['longitude'] ?? 0.0;

    List<Forecast> forecasts = await obterPrevisoes(latitude, longitude);
    AirQuality airQuality = await obterQualidadeAr(latitude, longitude);

    print('Coordenadas: Latitude: $latitude, Longitude: $longitude');
    print('Previsões do tempo:');
    for (var forecast in forecasts) {
      print(
          'Data: ${forecast.date}, Temperatura: ${forecast.temperatureCelsius.toStringAsFixed(2)}ºC, Condição: ${forecast.weatherCondition}, Umidade: ${forecast.humidity}%');
    }

    print('\nQualidade do Ar:');
    print('Índice: ${airQuality.index}');
    print('Components: ${airQuality.components}');
  } catch (e) {
    print('Erro durante a busca de dados: $e');
  }
}

Future<Map<String, double>> obterCoordenadas(String cidade) async {
  try {
    GeocodingResult geocodingResult = await getGeocoding(cidade);
    double latitude = geocodingResult.latitude;
    double longitude = geocodingResult.longitude;
    return {'latitude': latitude, 'longitude': longitude};
  } catch (e) {
    print('Erro ao obter coordenadas: $e');
    return {'latitude': 0.0, 'longitude': 0.0};
  }
}

Future<List<Forecast>> obterPrevisoes(double latitude, double longitude) async {
  try {
    List<Forecast> forecasts = await getForecast(latitude, longitude);
    return forecasts;
  } catch (e) {
    print('Erro ao obter previsões: $e');
    return [];
  }
}

Future<AirQuality> obterQualidadeAr(double latitude, double longitude) async {
  try {
    AirQuality airQuality = await getAirQuality(latitude, longitude);
    return airQuality;
  } catch (e) {
    print('Erro ao obter qualidade do ar: $e');
    return AirQuality(0, {});
  }
}
