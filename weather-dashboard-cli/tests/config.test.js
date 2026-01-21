const fs = require('fs');
const path = require('path');
const os = require('os');

// Create a temporary test config
const testConfigDir = path.join(os.tmpdir(), 'weather-dashboard-test');
const testConfigFile = path.join(testConfigDir, 'config.json');

// Clean up before tests
beforeAll(() => {
  try {
    if (fs.existsSync(testConfigFile)) {
      fs.unlinkSync(testConfigFile);
    }
    if (fs.existsSync(testConfigDir)) {
      // Remove all files in the directory first
      const files = fs.readdirSync(testConfigDir);
      for (const file of files) {
        fs.unlinkSync(path.join(testConfigDir, file));
      }
      fs.rmdirSync(testConfigDir);
    }
  } catch (error) {
    // Ignore cleanup errors
  }
});

// Clean up after tests
afterAll(() => {
  try {
    if (fs.existsSync(testConfigFile)) {
      fs.unlinkSync(testConfigFile);
    }
    if (fs.existsSync(testConfigDir)) {
      // Remove all files in the directory first
      const files = fs.readdirSync(testConfigDir);
      for (const file of files) {
        fs.unlinkSync(path.join(testConfigDir, file));
      }
      fs.rmdirSync(testConfigDir);
    }
  } catch (error) {
    // Ignore cleanup errors
  }
});

describe('ConfigManager', () => {
  let ConfigManager;
  let configManager;
  
  beforeEach(() => {
    // Reset module cache to get fresh instance
    jest.resetModules();
    
    // Mock fs and os to use temp directory
    jest.doMock('fs', () => ({
      ...jest.requireActual('fs'),
      existsSync: (filepath) => {
        if (filepath === testConfigDir) return fs.existsSync(testConfigDir);
        if (filepath === testConfigFile) return fs.existsSync(testConfigFile);
        return jest.requireActual('fs').existsSync(filepath);
      },
      mkdirSync: (dir, options) => {
        if (dir === testConfigDir) {
          if (!fs.existsSync(testConfigDir)) {
            fs.mkdirSync(dir, options);
          }
          return;
        }
        return jest.requireActual('fs').mkdirSync(dir, options);
      },
      writeFileSync: (filepath, data) => {
        if (filepath === testConfigFile) {
          fs.writeFileSync(filepath, data);
          return;
        }
        return jest.requireActual('fs').writeFileSync(filepath, data);
      },
      readFileSync: (filepath, encoding) => {
        if (filepath === testConfigFile) {
          if (fs.existsSync(testConfigFile)) {
            return fs.readFileSync(filepath, encoding);
          }
          throw new Error('File not found');
        }
        return jest.requireActual('fs').readFileSync(filepath, encoding);
      }
    }));
    
    jest.doMock('os', () => ({
      ...jest.requireActual('os'),
      homedir: () => testConfigDir
    }));
    
    // Import fresh instance
    const configModule = require('../src/config');
    ConfigManager = configModule.ConfigManager;
    configManager = new ConfigManager();
  });
  
  afterEach(() => {
    jest.resetModules();
    // Reset config to default
    try {
      if (fs.existsSync(testConfigFile)) {
        const defaultConfig = {
          apiKey: '',
          units: 'metric',
          language: 'en',
          defaultLocation: '',
          forecastDays: 5,
          apiBaseUrl: 'https://api.openweathermap.org/data/2.5',
          geoApiUrl: 'https://api.openweathermap.org/geo/1.0'
        };
        fs.writeFileSync(testConfigFile, JSON.stringify(defaultConfig, null, 2));
      }
    } catch (error) {
      // Ignore errors
    }
  });
  
  describe('constructor', () => {
    test('should initialize and allow setting values', () => {
      // Test that we can set and get values
      configManager.setUnits('imperial');
      expect(configManager.getUnits()).toBe('imperial');
      
      // Reset for other tests
      configManager.setUnits('metric');
    });
  });
  
  describe('get', () => {
    test('should return set values for keys', () => {
      configManager.set('units', 'imperial');
      expect(configManager.get('units')).toBe('imperial');
      
      // Reset for other tests
      configManager.set('units', 'metric');
    });
  });
  
  describe('setUnits', () => {
    test('should set valid units', () => {
      configManager.setUnits('imperial');
      expect(configManager.getUnits()).toBe('imperial');
    });
    
    test('should throw error for invalid units', () => {
      expect(() => configManager.setUnits('invalid')).toThrow('Invalid units');
    });
  });
  
  describe('setForecastDays', () => {
    test('should set valid forecast days', () => {
      configManager.setForecastDays(7);
      expect(configManager.getForecastDays()).toBe(7);
    });
    
    test('should throw error for invalid forecast days', () => {
      expect(() => configManager.setForecastDays(0)).toThrow('Forecast days must be between 1 and 8');
      expect(() => configManager.setForecastDays(9)).toThrow('Forecast days must be between 1 and 8');
    });
  });
});
