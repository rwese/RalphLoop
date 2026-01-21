#!/usr/bin/env node

const { Command } = require('commander');
const config = require('./config');
const weatherService = require('./services/weather');
const display = require('./utils/display');

class WeatherCLI {
  constructor() {
    this.program = new Command();
    this.setupProgram();
  }

  setupProgram() {
    this.program
      .name('weather-dashboard')
      .description('A sophisticated Weather Dashboard CLI tool')
      .version('1.0.0')
      .configureOutput({
        writeErr: (str) => process.stderr.write(str)
      });

    // Current weather command
    this.program
      .command('current [location]')
      .description('Get current weather for a location')
      .action(async (location) => {
        await this.handleCurrentWeather(location);
      });

    // Forecast command
    this.program
      .command('forecast [location]')
      .description('Get weather forecast for a location')
      .action(async (location) => {
        await this.handleForecast(location);
      });

    // Search command
    this.program
      .command('search <query>')
      .description('Search for locations')
      .action(async (query) => {
        await this.handleSearch(query);
      });

    // Config command
    this.program
      .command('config')
      .description('Manage configuration')
      .option('--set-api-key <key>', 'Set OpenWeatherMap API key')
      .option('--set-units <units>', 'Set temperature units (metric/imperial/standard)')
      .option('--set-language <lang>', 'Set language code')
      .option('--set-default-location <location>', 'Set default location')
      .option('--set-forecast-days <days>', 'Set number of forecast days (1-8)')
      .option('--show', 'Show current configuration')
      .option('--reset', 'Reset to defaults')
      .action(async (options) => {
        await this.handleConfig(options);
      });

    // Help command
    this.program
      .command('help')
      .description('Show help information')
      .action(() => {
        display.showHelp();
      });
  }

  async handleCurrentWeather(location) {
    try {
      // Use default location if none provided
      if (!location) {
        location = config.getDefaultLocation();
        if (!location) {
          display.showError('No location provided. Please specify a location or set a default location using:\n  weather-dashboard config --set-default-location "London, UK"');
          return;
        }
      }

      const weather = await weatherService.getCurrentWeather(location);
      display.showCurrentWeather(weather);
    } catch (error) {
      display.showError(error.message);
    }
  }

  async handleForecast(location) {
    try {
      // Use default location if none provided
      if (!location) {
        location = config.getDefaultLocation();
        if (!location) {
          display.showError('No location provided. Please specify a location or set a default location using:\n  weather-dashboard config --set-default-location "London, UK"');
          return;
        }
      }

      const forecast = await weatherService.getForecast(location);
      display.showForecast(forecast);
    } catch (error) {
      display.showError(error.message);
    }
  }

  async handleSearch(query) {
    try {
      const locations = await weatherService.searchLocations(query);
      display.showLocations(locations);
    } catch (error) {
      display.showError(error.message);
    }
  }

  async handleConfig(options) {
    try {
      if (options.show) {
        const configData = config.getAll();
        configData._configPath = config.getConfigPath();
        display.showConfig(configData);
        return;
      }

      if (options.reset) {
        config.reset();
        display.showSuccess('Configuration reset to defaults.');
        return;
      }

      if (options.setApiKey) {
        config.setApiKey(options.setApiKey);
        display.showSuccess('API key updated successfully.');
      }

      if (options.setUnits) {
        config.setUnits(options.setUnits);
        display.showSuccess(`Units set to ${options.setUnits}.`);
      }

      if (options.setLanguage) {
        config.setLanguage(options.setLanguage);
        display.showSuccess(`Language set to ${options.setLanguage}.`);
      }

      if (options.setDefaultLocation) {
        config.setDefaultLocation(options.setDefaultLocation);
        display.showSuccess(`Default location set to "${options.setDefaultLocation}".`);
      }

      if (options.setForecastDays) {
        config.setForecastDays(parseInt(options.setForecastDays));
        display.showSuccess(`Forecast days set to ${options.setForecastDays}.`);
      }

      // If no options provided, show current config
      if (!options.setApiKey && !options.setUnits && !options.setLanguage && 
          !options.setDefaultLocation && !options.setForecastDays && !options.reset) {
        const configData = config.getAll();
        configData._configPath = config.getConfigPath();
        display.showConfig(configData);
      }
    } catch (error) {
      display.showError(error.message);
    }
  }

  async run() {
    // Check if no arguments provided, show help
    if (process.argv.length === 2) {
      display.showHelp();
      return;
    }

    await this.program.parseAsync(process.argv);
  }
}

// Export for testing
module.exports = WeatherCLI;

// Main execution
if (require.main === module) {
  const cli = new WeatherCLI();
  cli.run().catch(error => {
    console.error('Unexpected error:', error);
    process.exit(1);
  });
}
