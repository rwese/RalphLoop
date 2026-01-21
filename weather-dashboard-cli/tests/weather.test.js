const { WeatherService } = require('../src/services/weather');

// Mock config for testing
jest.mock('../src/config', () => {
  const mockConfig = {
    apiKey: 'test-api-key',
    units: 'metric',
    language: 'en',
    defaultLocation: '',
    forecastDays: 5,
    apiBaseUrl: 'https://api.openweathermap.org/data/2.5',
    geoApiUrl: 'https://api.openweathermap.org/geo/1.0',
    getApiKey: () => mockConfig.apiKey,
    getUnits: () => mockConfig.units,
    getLanguage: () => mockConfig.language,
    getDefaultLocation: () => mockConfig.defaultLocation,
    getForecastDays: () => mockConfig.forecastDays,
    get: (key) => mockConfig[key]
  };
  
  return mockConfig;
});

describe('WeatherService', () => {
  let weatherService;
  
  beforeEach(() => {
    weatherService = new WeatherService();
  });
  
  describe('degreesToCardinal', () => {
    test('should convert 0 degrees to N', () => {
      expect(weatherService.degreesToCardinal(0)).toBe('N');
    });
    
    test('should convert 90 degrees to E', () => {
      expect(weatherService.degreesToCardinal(90)).toBe('E');
    });
    
    test('should convert 180 degrees to S', () => {
      expect(weatherService.degreesToCardinal(180)).toBe('S');
    });
    
    test('should convert 270 degrees to W', () => {
      expect(weatherService.degreesToCardinal(270)).toBe('W');
    });
    
    test('should convert 360 degrees to N', () => {
      expect(weatherService.degreesToCardinal(360)).toBe('N');
    });
    
    test('should convert 45 degrees to NE', () => {
      expect(weatherService.degreesToCardinal(45)).toBe('NE');
    });
    
    test('should convert 135 degrees to SE', () => {
      expect(weatherService.degreesToCardinal(135)).toBe('SE');
    });
    
    test('should convert 225 degrees to SW', () => {
      expect(weatherService.degreesToCardinal(225)).toBe('SW');
    });
    
    test('should convert 315 degrees to NW', () => {
      expect(weatherService.degreesToCardinal(315)).toBe('NW');
    });
  });
  
  describe('formatCurrentWeather', () => {
    test('should format current weather data correctly', () => {
      const mockWeatherData = {
        main: {
          temp: 20.5,
          feels_like: 19.8,
          humidity: 65,
          pressure: 1013
        },
        weather: [{
          description: 'clear sky',
          icon: '01d'
        }],
        wind: {
          speed: 3.5,
          deg: 180
        },
        visibility: 10000,
        clouds: {
          all: 0
        },
        sys: {
          country: 'US',
          sunrise: 1699999999,
          sunset: 1700044444
        }
      };
      
      const result = weatherService.formatCurrentWeather(mockWeatherData, 'New York');
      
      expect(result.location).toBe('New York');
      expect(result.country).toBe('US');
      expect(result.temperature).toBe('21°C');
      expect(result.feelsLike).toBe('20°C');
      expect(result.humidity).toBe('65%');
      expect(result.pressure).toBe('1013 hPa');
      expect(result.windSpeed).toBe('3.5 m/s');
      expect(result.windDirection).toBe('S');
      expect(result.description).toBe('clear sky');
      expect(result.visibility).toBe('10.0 km');
      expect(result.clouds).toBe('0%');
    });
  });
  
  describe('formatLocationResults', () => {
    test('should format location results correctly', () => {
      const mockLocations = [
        { name: 'New York', country: 'US', state: 'NY', lat: 40.7128, lon: -74.0060 },
        { name: 'London', country: 'GB', lat: 51.5074, lon: -0.1278 }
      ];
      
      const result = weatherService.formatLocationResults(mockLocations);
      
      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        name: 'New York',
        country: 'US',
        state: 'NY',
        lat: 40.7128,
        lon: -74.0060
      });
      expect(result[1]).toEqual({
        name: 'London',
        country: 'GB',
        state: '',
        lat: 51.5074,
        lon: -0.1278
      });
    });
  });
  
  describe('formatForecast', () => {
    test('should format forecast data correctly', () => {
      const mockForecastData = {
        list: [
          {
            dt: 1699999999,
            main: { temp: 15, humidity: 70 },
            weather: [{ main: 'Clouds', description: 'cloudy', icon: '03d' }],
            wind: { speed: 5 }
          },
          {
            dt: 1700086399,
            main: { temp: 18, humidity: 65 },
            weather: [{ main: 'Clear', description: 'clear sky', icon: '01d' }],
            wind: { speed: 3 }
          }
        ]
      };
      
      const result = weatherService.formatForecast(mockForecastData, 'Test City');
      
      expect(result.location).toBe('Test City');
      expect(result.forecasts).toBeDefined();
      expect(result.timestamp).toBeDefined();
    });
  });
});
