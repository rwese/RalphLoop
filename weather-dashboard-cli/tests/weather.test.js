// Mock axios before requiring WeatherService
jest.mock('axios');
const axios = require('axios');

const WeatherService = require('../src/services/weather');

describe('WeatherService', () => {
  let mockConfigManager;
  let weatherService;

  beforeEach(() => {
    mockConfigManager = {
      getApiKey: jest.fn().mockReturnValue('test-api-key'),
      setApiKey: jest.fn()
    };
    weatherService = new WeatherService(mockConfigManager);
    jest.clearAllMocks();
  });

  describe('constructor', () => {
    it('should initialize with config manager', () => {
      expect(weatherService.configManager).toBe(mockConfigManager);
      expect(weatherService.apiKey).toBe('test-api-key');
    });
  });

  describe('getCardinalDirection', () => {
    it('should return N for 0 degrees', () => {
      expect(weatherService.getCardinalDirection(0)).toBe('N');
    });

    it('should return E for 90 degrees', () => {
      expect(weatherService.getCardinalDirection(90)).toBe('E');
    });

    it('should return S for 180 degrees', () => {
      expect(weatherService.getCardinalDirection(180)).toBe('S');
    });

    it('should return W for 270 degrees', () => {
      expect(weatherService.getCardinalDirection(270)).toBe('W');
    });

    it('should return N for 360 degrees', () => {
      expect(weatherService.getCardinalDirection(360)).toBe('N');
    });

    it('should return N/A for null', () => {
      expect(weatherService.getCardinalDirection(null)).toBe('N/A');
    });

    it('should return N/A for undefined', () => {
      expect(weatherService.getCardinalDirection(undefined)).toBe('N/A');
    });

    it('should return correct direction for 45 degrees', () => {
      expect(weatherService.getCardinalDirection(45)).toBe('NE');
    });

    it('should return correct direction for 135 degrees', () => {
      expect(weatherService.getCardinalDirection(135)).toBe('SE');
    });

    it('should return correct direction for 225 degrees', () => {
      expect(weatherService.getCardinalDirection(225)).toBe('SW');
    });

    it('should return correct direction for 315 degrees', () => {
      expect(weatherService.getCardinalDirection(315)).toBe('NW');
    });
  });

  describe('getTemperatureUnit', () => {
    it('should return °C for metric', () => {
      expect(weatherService.getTemperatureUnit('metric')).toBe('°C');
    });

    it('should return °F for imperial', () => {
      expect(weatherService.getTemperatureUnit('imperial')).toBe('°F');
    });

    it('should return K for standard', () => {
      expect(weatherService.getTemperatureUnit('standard')).toBe('K');
    });

    it('should return °C for unknown', () => {
      expect(weatherService.getTemperatureUnit('unknown')).toBe('°C');
    });
  });

  describe('getSpeedUnit', () => {
    it('should return m/s for metric', () => {
      expect(weatherService.getSpeedUnit('metric')).toBe('m/s');
    });

    it('should return mph for imperial', () => {
      expect(weatherService.getSpeedUnit('imperial')).toBe('mph');
    });

    it('should return m/s for standard', () => {
      expect(weatherService.getSpeedUnit('standard')).toBe('m/s');
    });
  });

  describe('makeRequest', () => {
    it('should make successful request', async () => {
      const mockData = { temp: 20, humidity: 50 };
      axios.get.mockResolvedValue({ data: mockData });

      const result = await weatherService.makeRequest('https://test.com', { param: 'value' });

      expect(axios.get).toHaveBeenCalledWith('https://test.com', {
        params: { param: 'value', appid: 'test-api-key' },
        timeout: 10000
      });
      expect(result).toEqual(mockData);
    });

    it('should throw error for 401 status', async () => {
      axios.get.mockRejectedValue({
        response: { status: 401, statusText: 'Unauthorized' }
      });

      await expect(weatherService.makeRequest('https://test.com'))
        .rejects.toThrow('Invalid API key');
    });

    it('should throw error for 404 status', async () => {
      axios.get.mockRejectedValue({
        response: { status: 404, statusText: 'Not Found' }
      });

      await expect(weatherService.makeRequest('https://test.com'))
        .rejects.toThrow('Location not found');
    });

    it('should throw error for 429 status (rate limit)', async () => {
      axios.get.mockRejectedValue({
        response: { status: 429, statusText: 'Too Many Requests' }
      });

      await expect(weatherService.makeRequest('https://test.com'))
        .rejects.toThrow('API rate limit exceeded');
    });

    it('should throw error for 500 status (server error)', async () => {
      axios.get.mockRejectedValue({
        response: { status: 500, statusText: 'Internal Server Error' }
      });

      await expect(weatherService.makeRequest('https://test.com'))
        .rejects.toThrow('OpenWeatherMap server error');
    });

    it('should throw error for network errors', async () => {
      axios.get.mockRejectedValue(new Error('Network Error'));

      try {
        await weatherService.makeRequest('https://test.com');
        fail('Expected error to be thrown');
      } catch (error) {
        expect(error.message).toContain('Network Error');
      }
    });
  });

  describe('searchLocations', () => {
    it('should return search results', async () => {
      axios.get.mockResolvedValue({
        data: [
          { name: 'London', country: 'GB', lat: 51.5074, lon: -0.1278 },
          { name: 'London', country: 'CA', lat: 42.9837, lon: -81.2497 }
        ]
      });

      const results = await weatherService.searchLocations('London');

      expect(results).toHaveLength(2);
      expect(results[0].name).toBe('London');
      expect(results[0].country).toBe('GB');
    });

    it('should throw error for empty query', async () => {
      await expect(weatherService.searchLocations(''))
        .rejects.toThrow('Search query cannot be empty');
    });

    it('should throw error for short query', async () => {
      await expect(weatherService.searchLocations('L'))
        .rejects.toThrow('Search query must be at least 2 characters');
    });

    it('should return empty array for no results', async () => {
      axios.get.mockResolvedValue({ data: [] });

      const results = await weatherService.searchLocations('NonExistentCity123456');

      expect(results).toEqual([]);
    });
  });

  describe('processForecastData', () => {
    it('should process forecast data correctly', () => {
      const forecastList = [
        {
          dt: 1704067200, // 2024-01-01 00:00:00 UTC
          main: { temp_min: 10, temp_max: 20, humidity: 50, pressure: 1013 },
          wind: { speed: 5, deg: 180 },
          weather: [{ main: 'Clear', description: 'clear sky', icon: '01d' }]
        },
        {
          dt: 1704103200, // 2024-01-01 14:00:00 UTC
          main: { temp_min: 12, temp_max: 22, humidity: 55, pressure: 1015 },
          wind: { speed: 6, deg: 200 },
          weather: [{ main: 'Clouds', description: 'few clouds', icon: '02d' }]
        }
      ];

      const result = weatherService.processForecastData(forecastList, 'metric');

      expect(result).toHaveLength(1);
      expect(result[0].tempMin).toBe(10);
      expect(result[0].tempMax).toBe(22);
      // Average of 50 and 55 is 52.5, rounded to 53
      expect(result[0].humidity).toBe(53);
      // Average of 5 and 6 is 5.5
      expect(result[0].windSpeed).toBe(5.5);
    });

    it('should handle empty forecast list', () => {
      const result = weatherService.processForecastData([], 'metric');

      expect(result).toEqual([]);
    });

    it('should limit to 5 days', () => {
      const forecastList = Array.from({ length: 40 }, (_, i) => ({
        dt: 1704067200 + (i * 10800), // 3-hour intervals
        main: { temp_min: 10, temp_max: 20, humidity: 50, pressure: 1013 },
        wind: { speed: 5, deg: 180 },
        weather: [{ main: 'Clear', description: 'clear sky', icon: '01d' }]
      }));

      const result = weatherService.processForecastData(forecastList, 'metric');

      expect(result.length).toBeLessThanOrEqual(5);
    });
  });

  describe('updateApiKey', () => {
    it('should update API key from config manager', () => {
      mockConfigManager.getApiKey.mockReturnValue('new-key');
      weatherService.updateApiKey();

      expect(weatherService.apiKey).toBe('new-key');
    });
  });

  describe('setApiKey', () => {
    it('should update API key in service and config', () => {
      weatherService.setApiKey('new-api-key');

      expect(weatherService.apiKey).toBe('new-api-key');
      expect(mockConfigManager.setApiKey).toHaveBeenCalledWith('new-api-key');
    });
  });
});
