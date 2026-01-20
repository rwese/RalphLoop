#!/usr/bin/env node

const { Command } = require('commander');
const chalk = require('chalk');
const WeatherService = require('../src/weather-service');
const Formatter = require('../src/formatter');

const program = new Command();
const weatherService = new WeatherService();
const formatter = new Formatter();

program
  .name('weather')
  .description('A sophisticated command-line weather tool with beautiful terminal output')
  .version('1.0.0');

// Current weather command
program
  .command('current')
  .description('Get current weather for a location')
  .argument('<location>', 'Location name (city, country) or coordinates (lat,lon)')
  .option('-u, --units <units>', 'Temperature units (metric, imperial, kelvin)', 'metric')
  .action(async (location, options) => {
    try {
      const weatherData = await weatherService.getCurrentWeather(location, options.units);
      formatter.formatCurrentWeather(weatherData);
    } catch (error) {
      console.error(chalk.red('Error:'), error.message);
      process.exit(1);
    }
  });

// Forecast command
program
  .command('forecast')
  .description('Get weather forecast for a location')
  .argument('<location>', 'Location name (city, country) or coordinates (lat,lon)')
  .option('-d, --days <days>', 'Number of days (1-5)', '3')
  .option('-u, --units <units>', 'Temperature units (metric, imperial, kelvin)', 'metric')
  .action(async (location, options) => {
    try {
      const days = parseInt(options.days);
      if (isNaN(days) || days < 1 || days > 5) {
        throw new Error('Days must be a number between 1 and 5');
      }
      
      const forecastData = await weatherService.getForecast(location, days, options.units);
      formatter.formatForecast(forecastData);
    } catch (error) {
      console.error(chalk.red('Error:'), error.message);
      process.exit(1);
    }
  });

// Search command
program
  .command('search')
  .description('Search for locations by name')
  .argument('<query>', 'Location name to search for')
  .action(async (query) => {
    try {
      const locations = await weatherService.searchLocations(query);
      formatter.formatLocationSearch(locations);
    } catch (error) {
      console.error(chalk.red('Error:'), error.message);
      process.exit(1);
    }
  });

// Config command
program
  .command('config')
  .description('Manage configuration')
  .option('-s, --set <setting>', 'Set configuration value (format: key=value)')
  .action(async (options) => {
    try {
      if (options.set) {
        // Parse setting (format: key=value)
        const [key, ...valueParts] = options.set.split('=');
        if (!key || valueParts.length === 0) {
          throw new Error('Setting must be in format: key=value');
        }
        
        const value = valueParts.join('=');
        
        switch (key) {
          case 'apiKey':
            weatherService.setConfig('apiKey', value);
            console.log(chalk.green('API key updated'));
            break;
          case 'units':
            if (!['metric', 'imperial', 'kelvin'].includes(value)) {
              throw new Error('Units must be one of: metric, imperial, kelvin');
            }
            weatherService.setConfig('units', value);
            console.log(chalk.green(`Units set to ${value}`));
            break;
          default:
            throw new Error(`Unknown configuration key: ${key}`);
        }
      } else {
        // Show current configuration
        const config = weatherService.getConfig();
        formatter.formatConfig(config);
      }
    } catch (error) {
      console.error(chalk.red('Error:'), error.message);
      process.exit(1);
    }
  });

// Global error handler
process.on('unhandledRejection', (reason, promise) => {
  console.error(chalk.red('Unexpected error occurred'));
  console.error(chalk.red(reason.message || reason));
  process.exit(1);
});

program.parse();