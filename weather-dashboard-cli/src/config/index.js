const fs = require('fs');
const path = require('path');
const os = require('os');

class ConfigManager {
  constructor() {
    this.configDir = path.join(os.homedir(), '.weather-dashboard');
    this.configFile = path.join(this.configDir, 'config.json');
    this.defaultConfig = {
      apiKey: process.env.WEATHER_API_KEY || '',
      units: 'metric',
      language: 'en',
      defaultLocation: '',
      forecastDays: 5,
      apiBaseUrl: 'https://api.openweathermap.org/data/2.5',
      geoApiUrl: 'https://api.openweathermap.org/geo/1.0'
    };
    
    this.config = this.loadConfig();
  }

  loadConfig() {
    try {
      // Create config directory if it doesn't exist
      if (!fs.existsSync(this.configDir)) {
        fs.mkdirSync(this.configDir, { recursive: true });
      }

      // Load existing config or create default
      if (fs.existsSync(this.configFile)) {
        const fileConfig = JSON.parse(fs.readFileSync(this.configFile, 'utf8'));
        return { ...this.defaultConfig, ...fileConfig };
      }
      
      // Create default config file
      this.saveConfig(this.defaultConfig);
      return { ...this.defaultConfig };
    } catch (error) {
      console.warn('Warning: Could not load config file, using defaults');
      return { ...this.defaultConfig };
    }
  }

  saveConfig(config) {
    try {
      if (!fs.existsSync(this.configDir)) {
        fs.mkdirSync(this.configDir, { recursive: true });
      }
      fs.writeFileSync(this.configFile, JSON.stringify(config, null, 2));
    } catch (error) {
      console.error('Error saving config:', error.message);
    }
  }

  get(key) {
    // Environment variable takes precedence
    const envKey = key.toUpperCase().replace(/([A-Z])/g, '_$1');
    const envValue = process.env[`WEATHER_${envKey}`];
    
    if (envValue !== undefined) {
      return envValue;
    }
    
    return this.config[key];
  }

  set(key, value) {
    this.config[key] = value;
    this.saveConfig(this.config);
  }

  getApiKey() {
    return this.get('apiKey');
  }

  setApiKey(apiKey) {
    this.set('apiKey', apiKey);
  }

  getUnits() {
    return this.get('units');
  }

  setUnits(units) {
    const validUnits = ['metric', 'imperial', 'standard'];
    if (!validUnits.includes(units)) {
      throw new Error(`Invalid units: ${units}. Must be one of: ${validUnits.join(', ')}`);
    }
    this.set('units', units);
  }

  getLanguage() {
    return this.get('language');
  }

  setLanguage(language) {
    this.set('language', language);
  }

  getDefaultLocation() {
    return this.get('defaultLocation');
  }

  setDefaultLocation(location) {
    this.set('defaultLocation', location);
  }

  getForecastDays() {
    return this.get('forecastDays');
  }

  setForecastDays(days) {
    if (days < 1 || days > 8) {
      throw new Error('Forecast days must be between 1 and 8');
    }
    this.set('forecastDays', days);
  }

  getAll() {
    return { ...this.config };
  }

  reset() {
    this.config = { ...this.defaultConfig };
    this.saveConfig(this.config);
  }

  getConfigPath() {
    return this.configFile;
  }
}

// Export singleton instance
module.exports = new ConfigManager();

// Export class for testing
module.exports.ConfigManager = ConfigManager;
