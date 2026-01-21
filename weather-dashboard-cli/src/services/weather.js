const axios = require('axios');

class WeatherService {
  constructor(configManager) {
    this.configManager = configManager;
    this.baseUrl = 'https://api.openweathermap.org/data/2.5';
    this.geocodingUrl = 'https://api.openweathermap.org/geo/1.0/direct';
    this.apiKey = '';
    this.updateApiKey();
  }

  updateApiKey() {
    this.apiKey = this.configManager.getApiKey();
  }

  getApiKey() {
    return this.apiKey;
  }

  setApiKey(key) {
    this.apiKey = key;
    this.configManager.setApiKey(key);
  }

  async makeRequest(url, params = {}) {
    if (!this.apiKey) {
      throw new Error('API key not configured. Use "weather-dashboard config --api-key YOUR_API_KEY" to set it.');
    }

    try {
      const response = await axios.get(url, {
        params: {
          ...params,
          appid: this.apiKey
        },
        timeout: 10000
      });

      return response.data;
    } catch (error) {
      if (error.response) {
        switch (error.response.status) {
          case 401:
            throw new Error('Invalid API key. Please check your OpenWeatherMap API key.');
          case 404:
            throw new Error('Location not found. Please try a different search term.');
          case 429:
            throw new Error('API rate limit exceeded. Please wait a moment and try again.');
          case 500:
            throw new Error('OpenWeatherMap server error. Please try again later.');
          case 503:
            throw new Error('OpenWeatherMap service unavailable. Please try again later.');
          default:
            throw new Error(`API error: ${error.response.status} - ${error.response.statusText}`);
        }
      } else if (error.request) {
        throw new Error('Network error. Please check your internet connection.');
      } else {
        throw new Error(`Request failed: ${error.message}`);
      }
    }
  }

  async getCurrentWeather(location, units = 'metric') {
    this.updateApiKey();

    // First, get coordinates for the location
    const coordinates = await this.getCoordinates(location);

    if (!coordinates) {
      throw new Error(`Could not find location: ${location}`);
    }

    // Fetch current weather data
    const weatherData = await this.makeRequest(`${this.baseUrl}/weather`, {
      lat: coordinates.lat,
      lon: coordinates.lon,
      units: units === 'standard' ? 'standard' : units
    });

    return {
      location: {
        name: coordinates.name,
        country: coordinates.country,
        lat: coordinates.lat,
        lon: coordinates.lon
      },
      current: {
        temperature: weatherData.main.temp,
        feelsLike: weatherData.main.feels_like,
        humidity: weatherData.main.humidity,
        pressure: weatherData.main.pressure,
        windSpeed: weatherData.wind.speed,
        windDirection: weatherData.wind.deg,
        windGust: weatherData.wind.gust || null,
        visibility: weatherData.visibility,
        clouds: weatherData.clouds.all,
        weather: {
          main: weatherData.weather[0].main,
          description: weatherData.weather[0].description,
          icon: weatherData.weather[0].icon
        },
        sunrise: new Date(weatherData.sys.sunrise * 1000),
        sunset: new Date(weatherData.sys.sunset * 1000)
      },
      units: {
        temperature: this.getTemperatureUnit(units),
        speed: this.getSpeedUnit(units)
      }
    };
  }

  async getForecast(location, units = 'metric') {
    this.updateApiKey();

    // First, get coordinates for the location
    const coordinates = await this.getCoordinates(location);

    if (!coordinates) {
      throw new Error(`Could not find location: ${location}`);
    }

    // Fetch forecast data
    const forecastData = await this.makeRequest(`${this.baseUrl}/forecast`, {
      lat: coordinates.lat,
      lon: coordinates.lon,
      units: units === 'standard' ? 'standard' : units
    });

    // Process and group forecast data by day
    const dailyForecasts = this.processForecastData(forecastData.list, units);

    return {
      location: {
        name: coordinates.name,
        country: coordinates.country,
        lat: coordinates.lat,
        lon: coordinates.lon
      },
      forecast: dailyForecasts,
      units: {
        temperature: this.getTemperatureUnit(units),
        speed: this.getSpeedUnit(units)
      }
    };
  }

  async searchLocations(query) {
    this.updateApiKey();

    if (!query || query.trim().length === 0) {
      throw new Error('Search query cannot be empty');
    }

    if (query.length < 2) {
      throw new Error('Search query must be at least 2 characters');
    }

    const searchResults = await this.makeRequest(this.geocodingUrl, {
      q: query,
      limit: 10,
      appid: this.apiKey
    });

    if (!searchResults || searchResults.length === 0) {
      return [];
    }

    return searchResults.map(result => ({
      name: result.name,
      country: result.country,
      state: result.state || null,
      lat: result.lat,
      lon: result.lon
    }));
  }

  async getCoordinates(location) {
    this.updateApiKey();

    if (!location || location.trim().length === 0) {
      throw new Error('Location cannot be empty');
    }

    const searchResults = await this.makeRequest(this.geocodingUrl, {
      q: location,
      limit: 1,
      appid: this.apiKey
    });

    if (!searchResults || searchResults.length === 0) {
      return null;
    }

    return {
      name: searchResults[0].name,
      country: searchResults[0].country,
      state: searchResults[0].state || null,
      lat: searchResults[0].lat,
      lon: searchResults[0].lon
    };
  }

  processForecastData(forecastList, units) {
    const dailyData = {};

    forecastList.forEach(forecast => {
      const date = new Date(forecast.dt * 1000);
      const dateKey = date.toISOString().split('T')[0];

      if (!dailyData[dateKey]) {
        dailyData[dateKey] = {
          date: date,
          tempMin: Infinity,
          tempMax: -Infinity,
          humidity: [],
          pressure: [],
          windSpeed: [],
          windDirection: [],
          weather: [],
          hourly: []
        };
      }

      // Update daily min/max temperatures
      dailyData[dateKey].tempMin = Math.min(dailyData[dateKey].tempMin, forecast.main.temp_min);
      dailyData[dateKey].tempMax = Math.max(dailyData[dateKey].tempMax, forecast.main.temp_max);

      // Collect data for averaging
      dailyData[dateKey].humidity.push(forecast.main.humidity);
      dailyData[dateKey].pressure.push(forecast.main.pressure);
      dailyData[dateKey].windSpeed.push(forecast.wind.speed);
      dailyData[dateKey].windDirection.push(forecast.wind.deg || 0);

      // Store weather info (use the most common weather condition)
      dailyData[dateKey].weather.push({
        main: forecast.weather[0].main,
        description: forecast.weather[0].description,
        icon: forecast.weather[0].icon
      });

      // Store hourly data
      dailyData[dateKey].hourly.push({
        time: date,
        temperature: forecast.main.temp,
        feelsLike: forecast.main.feels_like,
        humidity: forecast.main.humidity,
        pressure: forecast.main.pressure,
        windSpeed: forecast.wind.speed,
        windDirection: forecast.wind.deg,
        weather: {
          main: forecast.weather[0].main,
          description: forecast.weather[0].description,
          icon: forecast.weather[0].icon
        }
      });
    });

    // Calculate averages and process each day
    return Object.keys(dailyData)
      .sort()
      .slice(0, 5)
      .map(dateKey => {
        const day = dailyData[dateKey];

        // Calculate average values
        const avg = arr => arr.length > 0 ? arr.reduce((a, b) => a + b, 0) / arr.length : 0;

        // Get the most common weather condition
        const weatherCounts = {};
        day.weather.forEach(w => {
          const key = w.main;
          weatherCounts[key] = (weatherCounts[key] || 0) + 1;
        });
        const dominantWeather = day.weather.reduce((max, w) => {
          const count = weatherCounts[w.main];
          return count > (weatherCounts[max.main] || 0) ? w : max;
        }, day.weather[0]);

        // Get wind direction as cardinal point
        const avgWindDirection = avg(day.windDirection);
        const cardinalDirection = this.getCardinalDirection(avgWindDirection);

        return {
          date: day.date,
          tempMin: Math.round(day.tempMin * 10) / 10,
          tempMax: Math.round(day.tempMax * 10) / 10,
          tempAvg: Math.round(avg(day.weather.map((_, i) => (day.tempMin + day.tempMax) / 2)) * 10) / 10,
          humidity: Math.round(avg(day.humidity)),
          pressure: Math.round(avg(day.pressure)),
          windSpeed: Math.round(avg(day.windSpeed) * 10) / 10,
          windDirection: cardinalDirection,
          weather: dominantWeather,
          hourly: day.hourly.map(h => ({
            time: h.time,
            temperature: Math.round(h.temperature * 10) / 10,
            feelsLike: Math.round(h.feelsLike * 10) / 10,
            humidity: h.humidity,
            weather: h.weather
          }))
        };
      });
  }

  getTemperatureUnit(units) {
    switch (units) {
      case 'imperial':
        return '°F';
      case 'standard':
        return 'K';
      default:
        return '°C';
    }
  }

  getSpeedUnit(units) {
    switch (units) {
      case 'imperial':
        return 'mph';
      default:
        return 'm/s';
    }
  }

  getCardinalDirection(degrees) {
    if (degrees === null || degrees === undefined) {
      return 'N/A';
    }

    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    const index = Math.round(degrees / 22.5) % 16;
    return directions[index];
  }
}

module.exports = WeatherService;
