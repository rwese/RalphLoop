#!/usr/bin/env node

const { Command } = require('commander');
const figlet = require('figlet');
const chalk = require('chalk');
const path = require('path');
const os = require('os');

const packageJson = require('../package.json');
const WeatherService = require('../src/services/weather');
const ConfigManager = require('../src/config');
const DisplayUtils = require('../src/utils/display');

// Initialize configuration and services
const configManager = new ConfigManager();
const weatherService = new WeatherService(configManager);
const displayUtils = new DisplayUtils(configManager);

// Create CLI program
const program = new Command();

program
  .name('weather-dashboard')
  .description(chalk.cyan('A powerful command-line tool for weather data'))
  .version(packageJson.version)
  .configureOutput({
    writeErr: (str) => process.stderr.write(chalk.red(str)),
    outputError: (str, write) => write(chalk.red.bold('Error: ') + str)
  });

// Display welcome banner
program.addHelpText('beforeAll', () => {
  console.log(
    chalk.cyan(
      figlet.textSync('Weather', {
        font: 'Standard',
        horizontalLayout: 'default',
        verticalLayout: 'default'
      })
    )
  );
  console.log(chalk.cyan.bold('\n  Weather Dashboard CLI'));
  console.log(chalk.gray('  Version ' + packageJson.version + '\n'));
});

// Current weather command
program
  .command('current [location]')
  .description('Get current weather conditions for a location')
  .option('-u, --units <type>', 'Temperature units: metric, imperial, or standard', 'metric')
  .action(async (location, options) => {
    try {
      const config = configManager.getConfig();
      const units = options.units || config.units || 'metric';

      if (!location) {
        location = config.defaultLocation;
        if (!location) {
          console.log(chalk.yellow('Please provide a location or set a default location using:'));
          console.log(chalk.cyan('  weather-dashboard config --set-default-location "Your City"'));
          return;
        }
      }

      console.log(chalk.blue('\n🌤️  Fetching current weather for ' + location + '...\n'));

      const weatherData = await weatherService.getCurrentWeather(location, units);
      displayUtils.displayCurrentWeather(weatherData, location, units);
    } catch (error) {
      displayUtils.handleError(error, 'current weather');
    }
  });

// Forecast command
program
  .command('forecast [location]')
  .description('Get 5-day weather forecast for a location')
  .option('-u, --units <type>', 'Temperature units: metric, imperial, or standard', 'metric')
  .action(async (location, options) => {
    try {
      const config = configManager.getConfig();
      const units = options.units || config.units || 'metric';

      if (!location) {
        location = config.defaultLocation;
        if (!location) {
          console.log(chalk.yellow('Please provide a location or set a default location using:'));
          console.log(chalk.cyan('  weather-dashboard config --set-default-location "Your City"'));
          return;
        }
      }

      console.log(chalk.blue('\n📅 Fetching 5-day forecast for ' + location + '...\n'));

      const forecastData = await weatherService.getForecast(location, units);
      displayUtils.displayForecast(forecastData, location, units);
    } catch (error) {
      displayUtils.handleError(error, 'forecast');
    }
  });

// Search command
program
  .command('search <query>')
  .description('Search for locations worldwide')
  .action(async (query) => {
    try {
      console.log(chalk.blue('\n🔍 Searching for "' + query + '"...\n'));

      const locations = await weatherService.searchLocations(query);
      displayUtils.displaySearchResults(locations, query);
    } catch (error) {
      displayUtils.handleError(error, 'search');
    }
  });

// Config command
program
  .command('config')
  .description('Manage application settings')
  .option('--api-key <key>', 'Set OpenWeatherMap API key')
  .option('--set-default-location <location>', 'Set default location')
  .option('--units <type>', 'Set default units: metric, imperial, or standard')
  .option('--show', 'Display current configuration')
  .action((options) => {
    try {
      if (options.show) {
        displayUtils.displayConfiguration(configManager.getConfig());
      } else if (options.apiKey) {
        configManager.setApiKey(options.apiKey);
        console.log(chalk.green('✓ API key set successfully'));
      } else if (options.setDefaultLocation) {
        configManager.setDefaultLocation(options.setDefaultLocation);
        console.log(chalk.green('✓ Default location set to: ' + options.setDefaultLocation));
      } else if (options.units) {
        if (['metric', 'imperial', 'standard'].includes(options.units)) {
          configManager.setUnits(options.units);
          console.log(chalk.green('✓ Default units set to: ' + options.units));
        } else {
          console.log(chalk.red('Invalid units. Use: metric, imperial, or standard'));
        }
      } else {
        displayUtils.displayConfiguration(configManager.getConfig());
      }
    } catch (error) {
      displayUtils.handleError(error, 'configuration');
    }
  });

// Parse arguments
program.parse(process.argv);

// Display help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}
