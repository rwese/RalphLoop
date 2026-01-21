const fs = require('fs');
const path = require('path');
const os = require('os');

class ConfigManager {
  constructor() {
    this.configDir = path.join(os.homedir(), '.weather-dashboard');
    this.configFile = path.join(this.configDir, 'config.json');
    this.defaultConfig = {
      apiKey: process.env.WEATHER_API_KEY || '',
      units: process.env.WEATHER_UNITS || 'metric',
      defaultLocation: process.env.WEATHER_DEFAULT_LOCATION || '',
      language: process.env.WEATHER_LANGUAGE || 'en'
    };
    this.config = this.loadConfig();
  }

  loadConfig() {
    try {
      if (fs.existsSync(this.configFile)) {
        const fileContent = fs.readFileSync(this.configFile, 'utf8');
        const loadedConfig = JSON.parse(fileContent);
        return { ...this.defaultConfig, ...loadedConfig };
      }
    } catch (error) {
      console.error('Error loading config:', error.message);
    }
    return { ...this.defaultConfig };
  }

  saveConfig() {
    try {
      // Ensure config directory exists
      if (!fs.existsSync(this.configDir)) {
        fs.mkdirSync(this.configDir, { recursive: true });
      }

      // Only save non-default values
      const configToSave = {};
      if (this.config.apiKey && this.config.apiKey !== this.defaultConfig.apiKey) {
        configToSave.apiKey = this.config.apiKey;
      }
      if (this.config.units && this.config.units !== this.defaultConfig.units) {
        configToSave.units = this.config.units;
      }
      if (this.config.defaultLocation && this.config.defaultLocation !== this.defaultConfig.defaultLocation) {
        configToSave.defaultLocation = this.config.defaultLocation;
      }
      if (this.config.language && this.config.language !== this.defaultConfig.language) {
        configToSave.language = this.config.language;
      }

      fs.writeFileSync(this.configFile, JSON.stringify(configToSave, null, 2));
    } catch (error) {
      throw new Error('Failed to save configuration: ' + error.message);
    }
  }

  getConfig() {
    return { ...this.config };
  }

  getApiKey() {
    return this.config.apiKey;
  }

  setApiKey(key) {
    this.config.apiKey = key;
    this.saveConfig();
  }

  getUnits() {
    return this.config.units;
  }

  setUnits(units) {
    this.config.units = units;
    this.saveConfig();
  }

  getDefaultLocation() {
    return this.config.defaultLocation;
  }

  setDefaultLocation(location) {
    this.config.defaultLocation = location;
    this.saveConfig();
  }

  getLanguage() {
    return this.config.language;
  }

  setLanguage(language) {
    this.config.language = language;
    this.saveConfig();
  }

  validateConfig() {
    const errors = [];

    if (!this.config.apiKey) {
      errors.push('API key is not set. Get a free API key at https://openweathermap.org/api');
    }

    if (!['metric', 'imperial', 'standard'].includes(this.config.units)) {
      errors.push('Invalid units configuration. Use: metric, imperial, or standard');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

module.exports = ConfigManager;
