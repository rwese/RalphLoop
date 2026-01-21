// Mock fs module before requiring ConfigManager
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  mkdirSync: jest.fn(),
  writeFileSync: jest.fn(),
  readFileSync: jest.fn()
}));

// Mock os module
jest.mock('os', () => ({
  homedir: () => '/home/user'
}));

const fs = require('fs');
const ConfigManager = require('../src/config');

describe('ConfigManager', () => {
  const mockConfigDir = '/home/user/.weather-dashboard';
  const mockConfigFile = `${mockConfigDir}/config.json`;

  beforeEach(() => {
    jest.clearAllMocks();
    // Default mock implementations
    fs.existsSync.mockReturnValue(false);
    fs.mkdirSync.mockReturnValue(undefined);
    fs.writeFileSync.mockReturnValue(undefined);
    fs.readFileSync.mockReturnValue('{}');
  });

  describe('constructor', () => {
    it('should load existing config file', () => {
      const existingConfig = JSON.stringify({
        apiKey: 'test-key',
        units: 'imperial',
        defaultLocation: 'New York'
      });
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(existingConfig);

      const configManager = new ConfigManager();
      const config = configManager.getConfig();

      expect(config.apiKey).toBe('test-key');
      expect(config.units).toBe('imperial');
      expect(config.defaultLocation).toBe('New York');
    });

    it('should use defaults when config file is empty or invalid', () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue('invalid json');

      const configManager = new ConfigManager();
      const config = configManager.getConfig();

      expect(config.apiKey).toBe('');
      expect(config.units).toBe('metric');
    });
  });

  describe('getConfig', () => {
    it('should return a copy of the config', () => {
      const configManager = new ConfigManager();
      const config1 = configManager.getConfig();
      const config2 = configManager.getConfig();

      expect(config1).not.toBe(config2);
      expect(config1).toEqual(config2);
    });
  });

  describe('setApiKey', () => {
    it('should update api key and save config', () => {
      const configManager = new ConfigManager();
      configManager.setApiKey('new-api-key');

      expect(fs.writeFileSync).toHaveBeenCalled();
      const savedConfig = JSON.parse(fs.writeFileSync.mock.calls[0][1]);
      expect(savedConfig.apiKey).toBe('new-api-key');
    });
  });

  describe('setUnits', () => {
    it('should update units to valid value', () => {
      const configManager = new ConfigManager();
      configManager.setUnits('imperial');

      expect(fs.writeFileSync).toHaveBeenCalled();
      const savedConfig = JSON.parse(fs.writeFileSync.mock.calls[0][1]);
      expect(savedConfig.units).toBe('imperial');
    });
  });

  describe('setDefaultLocation', () => {
    it('should update default location', () => {
      const configManager = new ConfigManager();
      configManager.setDefaultLocation('London');

      expect(fs.writeFileSync).toHaveBeenCalled();
      const savedConfig = JSON.parse(fs.writeFileSync.mock.calls[0][1]);
      expect(savedConfig.defaultLocation).toBe('London');
    });
  });

  describe('validateConfig', () => {
    it('should return valid when api key is set', () => {
      const existingConfig = JSON.stringify({ apiKey: 'test-key' });
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(existingConfig);

      const configManager = new ConfigManager();
      const result = configManager.validateConfig();

      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should return invalid when api key is not set', () => {
      const configManager = new ConfigManager();
      const result = configManager.validateConfig();

      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors[0]).toContain('API key');
    });

    it('should return invalid for invalid units', () => {
      const existingConfig = JSON.stringify({ apiKey: 'test-key', units: 'invalid' });
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(existingConfig);

      const configManager = new ConfigManager();
      const result = configManager.validateConfig();

      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('units'))).toBe(true);
    });
  });
});

describe('ConfigManager with Environment Variables', () => {
  beforeEach(() => {
    jest.resetModules();
    process.env.WEATHER_API_KEY = 'env-api-key';
    process.env.WEATHER_UNITS = 'imperial';
    process.env.WEATHER_DEFAULT_LOCATION = 'Env City';
  });

  afterEach(() => {
    delete process.env.WEATHER_API_KEY;
    delete process.env.WEATHER_UNITS;
    delete process.env.WEATHER_DEFAULT_LOCATION;
  });

  it('should use environment variables when no config file exists', () => {
    const fs = require('fs');
    fs.existsSync.mockReturnValue(false);
    fs.readFileSync.mockReturnValue('{}');

    const ConfigManager = require('../src/config');
    const configManager = new ConfigManager();
    const config = configManager.getConfig();

    expect(config.apiKey).toBe('env-api-key');
    expect(config.units).toBe('imperial');
    expect(config.defaultLocation).toBe('Env City');
  });
});
