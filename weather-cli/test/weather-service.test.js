const WeatherService = require('../src/weather-service');

describe('WeatherService', () => {
  let weatherService;

  beforeEach(() => {
    weatherService = new WeatherService();
  });

  describe('Constructor', () => {
    test('should initialize with default values', () => {
      expect(weatherService.baseUrl).toBe('https://api.openweathermap.org/data/2.5');
      expect(weatherService.geoUrl).toBe('https://api.openweathermap.org/geo/1.0');
      expect(weatherService.units).toBeDefined();
    });
  });

  describe('Configuration Management', () => {
    test('should load config from file or return empty', () => {
      const config = weatherService.loadConfig();
      expect(typeof config).toBe('object');
    });

    test('should set configuration values', () => {
      weatherService.setConfig('units', 'imperial');
      expect(weatherService.units).toBe('imperial');
    });

    test('should get configuration status', () => {
      const config = weatherService.getConfig();
      expect(config).toHaveProperty('apiKey');
      expect(config).toHaveProperty('units');
      expect(config).toHaveProperty('configFile');
    });
  });

  describe('Location Validation', () => {
    test('should throw error when API key is missing', async () => {
      weatherService.apiKey = null;
      
      await expect(weatherService.getCurrentWeather('London'))
        .rejects.toThrow('OpenWeatherMap API key not configured');
    });

    test('should throw error when API key is missing for forecast', async () => {
      weatherService.apiKey = null;
      
      await expect(weatherService.getForecast('London'))
        .rejects.toThrow('OpenWeatherMap API key not configured');
    });

    test('should validate forecast days range', async () => {
      weatherService.apiKey = 'test-key';
      
      jest.spyOn(weatherService, 'getLocationCoords').mockResolvedValue({
        name: 'London',
        country: 'UK',
        lat: 51.5074,
        lon: -0.1278
      });

      await expect(weatherService.getForecast('London', 0))
        .rejects.toThrow('Forecast days must be between 1 and 5');
        
      await expect(weatherService.getForecast('London', 6))
        .rejects.toThrow('Forecast days must be between 1 and 5');
    });
  });

  describe('Location Search', () => {
    test('should handle search errors gracefully', async () => {
      const axios = require('axios');
      jest.spyOn(axios, 'get').mockRejectedValue(new Error('Network error'));
      
      await expect(weatherService.searchLocations('London'))
        .rejects.toThrow('Network error');
    });
  });
});