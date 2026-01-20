const axios = require('axios');
const fs = require('fs');
const path = require('path');

class WeatherService {
  constructor() {
    this.apiKey = process.env.OPENWEATHER_API_KEY || this.loadConfig().apiKey;
    this.baseUrl = 'https://api.openweathermap.org/data/2.5';
    this.geoUrl = 'https://api.openweathermap.org/geo/1.0';
    this.configPath = path.join(process.env.HOME || process.env.USERPROFILE || '.', '.weather-cli.json');
    this.units = this.loadConfig().units || 'metric';
  }

  loadConfig() {
    try {
      if (fs.existsSync(this.configPath)) {
        const configData = fs.readFileSync(this.configPath, 'utf8');
        return JSON.parse(configData);
      }
    } catch (error) {
    }
    return {};
  }

  saveConfig(config) {
    try {
      fs.writeFileSync(this.configPath, JSON.stringify(config, null, 2));
    } catch (error) {
      console.warn('Warning: Could not save configuration file');
    }
  }

  setConfig(key, value) {
    const config = this.loadConfig();
    config[key] = value;
    this.saveConfig(config);
    if (key === 'apiKey') this.apiKey = value;
    if (key === 'units') this.units = value;
  }

  getConfig() {
    return {
      apiKey: this.apiKey ? '***SET***' : 'NOT SET',
      units: this.units,
      configFile: this.configPath
    };
  }

  async getCurrentWeather(location, units = 'metric') {
    if (!this.apiKey) {
      throw new Error('OpenWeatherMap API key not configured. Set OPENWEATHER_API_KEY environment variable or use "weather config --set apiKey=YOUR_KEY"');
    }

    try {
      const coords = await this.getLocationCoords(location);
      const response = await axios.get(`${this.baseUrl}/weather`, {
        params: { lat: coords.lat, lon: coords.lon, appid: this.apiKey, units: units }
      });

      return {
        location: coords.name,
        country: coords.country,
        coordinates: { lat: coords.lat, lon: coords.lon },
        current: response.data,
        units: units
      };
    } catch (error) {
      if (error.response && error.response.status === 401) {
        throw new Error('Invalid API key. Please check your OpenWeatherMap API key.');
      } else if (error.response && error.response.status === 404) {
        throw new Error(`Location "${location}" not found. Please check location name.`);
      } else if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
        throw new Error('Network error. Please check your internet connection.');
      } else {
        throw new Error(`Failed to fetch weather data: ${error.message}`);
      }
    }
  }

  async getForecast(location, days = 3, units = 'metric') {
    if (!this.apiKey) {
      throw new Error('OpenWeatherMap API key not configured. Set OPENWEATHER_API_KEY environment variable or use "weather config --set apiKey=YOUR_KEY"');
    }

    if (days < 1 || days > 5) {
      throw new Error('Forecast days must be between 1 and 5');
    }

    try {
      const coords = await this.getLocationCoords(location);
      const response = await axios.get(`${this.baseUrl}/forecast`, {
        params: { lat: coords.lat, lon: coords.lon, appid: this.apiKey, units: units, cnt: days * 8 }
      });

      const dailyForecasts = this.groupForecastsByDay(response.data.list, days);

      return {
        location: coords.name,
        country: coords.country,
        coordinates: { lat: coords.lat, lon: coords.lon },
        forecasts: dailyForecasts,
        units: units
      };
    } catch (error) {
      if (error.response && error.response.status === 401) {
        throw new Error('Invalid API key. Please check your OpenWeatherMap API key.');
      } else if (error.response && error.response.status === 404) {
        throw new Error(`Location "${location}" not found. Please check location name.`);
      } else if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
        throw new Error('Network error. Please check your internet connection.');
      } else {
        throw new Error(`Failed to fetch forecast data: ${error.message}`);
      }
    }
  }

  async searchLocations(query) {
    try {
      const response = await axios.get(`${this.geoUrl}/direct`, {
        params: { q: query, limit: 10, appid: this.apiKey || 'demo' }
      });

      return response.data.map(location => ({
        name: location.name,
        country: location.country,
        state: location.state,
        coordinates: { lat: location.lat, lon: location.lon }
      }));
    } catch (error) {
      if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
        throw new Error('Network error. Please check your internet connection.');
      } else {
        throw new Error(`Failed to search locations: ${error.message}`);
      }
    }
  }

  async getLocationCoords(location) {
    try {
      const coordsMatch = location.match(/^(-?\d+\.?\d*),\s*(-?\d+\.?\d*)$/);
      if (coordsMatch) {
        const lat = parseFloat(coordsMatch[1]);
        const lon = parseFloat(coordsMatch[2]);
        
        const reverseResponse = await axios.get(`${this.geoUrl}/reverse`, {
          params: { lat: lat, lon: lon, limit: 1, appid: this.apiKey }
        });

        if (reverseResponse.data.length > 0) {
          const locationData = reverseResponse.data[0];
          return { name: locationData.name, country: locationData.country, lat: lat, lon: lon };
        } else {
          return { name: `${lat}, ${lon}`, country: 'Unknown', lat: lat, lon: lon };
        }
      }

      const response = await axios.get(`${this.geoUrl}/direct`, {
        params: { q: location, limit: 1, appid: this.apiKey }
      });

      if (response.data.length === 0) {
        throw new Error(`Location "${location}" not found`);
      }

      const locationData = response.data[0];
      return {
        name: locationData.name,
        country: locationData.country,
        lat: locationData.lat,
        lon: locationData.lon
      };
    } catch (error) {
      if (error.response && error.response.status === 401) {
        throw new Error('API key required for location lookup. Please set OPENWEATHER_API_KEY.');
      } else if (error.message.includes('not found')) {
        throw error;
      } else {
        throw new Error(`Failed to resolve location: ${error.message}`);
      }
    }
  }

  groupForecastsByDay(forecasts, days) {
    const dailyForecasts = [];
    const today = new Date();
    
    for (let i = 0; i < days; i++) {
      const targetDate = new Date(today);
      targetDate.setDate(today.getDate() + i);
      const dateStr = targetDate.toISOString().split('T')[0];
      
      const dayForecasts = forecasts.filter(f => f.dt_txt.startsWith(dateStr));

      if (dayForecasts.length > 0) {
        const temps = dayForecasts.map(f => f.main.temp);
        const mainForecast = dayForecasts[Math.floor(dayForecasts.length / 2)];

        dailyForecasts.push({
          date: dateStr,
          temp_min: Math.min(...temps),
          temp_max: Math.max(...temps),
          main: mainForecast.main,
          weather: mainForecast.weather,
          wind: mainForecast.wind,
          humidity: mainForecast.main.humidity,
          forecasts: dayForecasts
        });
      }
    }

    return dailyForecasts;
  }
}

module.exports = WeatherService;