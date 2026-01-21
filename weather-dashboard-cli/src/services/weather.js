const axios = require('axios');
const config = require('../config');

class WeatherService {
  constructor() {
    this.baseUrl = config.get('apiBaseUrl');
    this.geoUrl = config.get('geoApiUrl');
    this.apiKey = config.getApiKey();
    this.units = config.getUnits();
    this.language = config.getLanguage();
  }

  refreshConfig() {
    this.apiKey = config.getApiKey();
    this.units = config.getUnits();
    this.language = config.getLanguage();
  }

  async getCurrentWeather(location) {
    this.refreshConfig();
    
    if (!this.apiKey) {
      throw new Error('API key not configured. Use "weather-dashboard config --set-api-key YOUR_API_KEY" to set your OpenWeatherMap API key.');
    }

    try {
      const locationData = await this.geocodeLocation(location);
      const { lat, lon, name } = locationData;

      const response = await axios.get(`${this.baseUrl}/weather`, {
        params: {
          lat,
          lon,
          appid: this.apiKey,
          units: this.units,
          lang: this.language
        },
        timeout: 10000
      });

      return this.formatCurrentWeather(response.data, name);
    } catch (error) {
      this.handleApiError(error, 'current weather');
    }
  }

  async getForecast(location) {
    this.refreshConfig();
    
    if (!this.apiKey) {
      throw new Error('API key not configured. Use "weather-dashboard config --set-api-key YOUR_API_KEY" to set your OpenWeatherMap API key.');
    }

    try {
      const locationData = await this.geocodeLocation(location);
      const { lat, lon, name } = locationData;

      const response = await axios.get(`${this.baseUrl}/forecast`, {
        params: {
          lat,
          lon,
          appid: this.apiKey,
          units: this.units,
          lang: this.language,
          cnt: config.getForecastDays() * 8 // 3-hour intervals, 8 per day
        },
        timeout: 10000
      });

      return this.formatForecast(response.data, name);
    } catch (error) {
      this.handleApiError(error, 'forecast');
    }
  }

  async searchLocations(query) {
    this.refreshConfig();
    
    if (!this.apiKey) {
      throw new Error('API key not configured. Use "weather-dashboard config --set-api-key YOUR_API_KEY" to set your OpenWeatherMap API key.');
    }

    try {
      const response = await axios.get(`${this.geoApiUrl}/direct`, {
        params: {
          q: query,
          limit: 10,
          appid: this.apiKey
        },
        timeout: 10000
      });

      return this.formatLocationResults(response.data);
    } catch (error) {
      this.handleApiError(error, 'location search');
    }
  }

  async geocodeLocation(location) {
    try {
      const response = await axios.get(`${this.geoApiUrl}/direct`, {
        params: {
          q: location,
          limit: 1,
          appid: this.apiKey
        },
        timeout: 10000
      });

      if (response.data.length === 0) {
        throw new Error(`Location "${location}" not found. Please try a different search term.`);
      }

      return {
        lat: response.data[0].lat,
        lon: response.data[0].lon,
        name: response.data[0].name,
        country: response.data[0].country,
        state: response.data[0].state
      };
    } catch (error) {
      if (error.message.includes('Location')) {
        throw error;
      }
      this.handleApiError(error, 'geocoding');
    }
  }

  formatCurrentWeather(data, locationName) {
    const unitSymbol = this.units === 'imperial' ? '°F' : this.units === 'standard' ? 'K' : '°C';
    const speedSymbol = this.units === 'imperial' ? 'mph' : 'm/s';

    return {
      location: locationName,
      country: data.sys.country,
      temperature: `${Math.round(data.main.temp)}${unitSymbol}`,
      feelsLike: `${Math.round(data.main.feels_like)}${unitSymbol}`,
      humidity: `${data.main.humidity}%`,
      pressure: `${data.main.pressure} hPa`,
      windSpeed: `${data.wind.speed} ${speedSymbol}`,
      windDirection: this.degreesToCardinal(data.wind.deg),
      description: data.weather[0].description,
      icon: data.weather[0].icon,
      iconUrl: `https://openweathermap.org/img/wn/${data.weather[0].icon}@2x.png`,
      visibility: `${(data.visibility / 1000).toFixed(1)} km`,
      clouds: `${data.clouds.all}%`,
      sunrise: new Date(data.sys.sunrise * 1000).toLocaleTimeString(),
      sunset: new Date(data.sys.sunset * 1000).toLocaleTimeString(),
      timestamp: new Date().toISOString()
    };
  }

  formatForecast(data, locationName) {
    const unitSymbol = this.units === 'imperial' ? '°F' : this.units === 'standard' ? 'K' : '°C';
    
    // Group forecasts by day
    const dailyForecasts = {};
    
    data.list.forEach(item => {
      const date = new Date(item.dt * 1000).toLocaleDateString();
      
      if (!dailyForecasts[date]) {
        dailyForecasts[date] = {
          date,
          temps: [],
          weather: [],
          humidity: [],
          windSpeed: [],
          details: []
        };
      }
      
      dailyForecasts[date].temps.push(item.main.temp);
      dailyForecasts[date].weather.push(item.weather[0]);
      dailyForecasts[date].humidity.push(item.main.humidity);
      dailyForecasts[date].windSpeed.push(item.wind.speed);
      dailyForecasts[date].details.push({
        time: new Date(item.dt * 1000).toLocaleTimeString(),
        temp: `${Math.round(item.main.temp)}${unitSymbol}`,
        description: item.weather[0].description,
        humidity: `${item.main.humidity}%`,
        windSpeed: `${item.wind.speed} m/s`
      });
    });

    // Calculate daily averages
    const forecasts = Object.values(dailyForecasts).slice(0, config.getForecastDays()).map(day => ({
      date: day.date,
      tempMin: `${Math.round(Math.min(...day.temps))}${unitSymbol}`,
      tempMax: `${Math.round(Math.max(...day.temps))}${unitSymbol}`,
      avgTemp: `${Math.round(day.temps.reduce((a, b) => a + b, 0) / day.temps.length)}${unitSymbol}`,
      mainWeather: day.weather[0].main,
      description: day.weather[0].description,
      icon: day.weather[0].icon,
      humidity: `${Math.round(day.humidity.reduce((a, b) => a + b, 0) / day.humidity.length)}%`,
      windSpeed: `${(day.windSpeed.reduce((a, b) => a + b, 0) / day.windSpeed.length).toFixed(1)} m/s`,
      hourly: day.details
    }));

    return {
      location: locationName,
      units: this.units,
      forecasts,
      timestamp: new Date().toISOString()
    };
  }

  formatLocationResults(data) {
    return data.map(item => ({
      name: item.name,
      country: item.country,
      state: item.state || '',
      lat: item.lat,
      lon: item.lon
    }));
  }

  degreesToCardinal(degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    const index = Math.round(degrees / 22.5) % 16;
    return directions[index];
  }

  handleApiError(error, context) {
    if (error.response) {
      const status = error.response.status;
      
      switch (status) {
      case 401:
        throw new Error('Invalid API key. Please check your OpenWeatherMap API key.');
      case 404:
        throw new Error('Weather data not found for the requested location.');
      case 429:
        throw new Error('API rate limit exceeded. Please wait a moment and try again.');
      case 500:
      case 502:
      case 503:
      case 504:
        throw new Error('OpenWeatherMap service is temporarily unavailable. Please try again later.');
      default:
        throw new Error(`API error (${status}): ${error.response.data?.message || 'Unknown error'} occurred while fetching ${context}.`);
      }
    } else if (error.request) {
      throw new Error('Network error: Unable to reach OpenWeatherMap API. Please check your internet connection.');
    } else if (error.code === 'ECONNABORTED') {
      throw new Error('Request timeout: OpenWeatherMap API did not respond in time. Please try again.');
    } else {
      throw new Error(`Unexpected error occurred while fetching ${context}: ${error.message}`);
    }
  }
}

// Export singleton instance
module.exports = new WeatherService();

// Export class for testing
module.exports.WeatherService = WeatherService;
