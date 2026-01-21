const chalk = require('chalk');
const figlet = require('figlet');

class DisplayUtils {
  constructor() {
    this.weatherIcons = {
      '01d': '☀️', '01n': '🌙',
      '02d': '⛅', '02n': '☁️',
      '03d': '☁️', '03n': '☁️',
      '04d': '☁️', '04n': '☁️',
      '09d': '🌧️', '09n': '🌧️',
      '10d': '🌦️', '10n': '🌧️',
      '11d': '⛈️', '11n': '⛈️',
      '13d': '❄️', '13n': '❄️',
      '50d': '🌫️', '50n': '🌫️'
    };
  }

  showBanner() {
    const banner = figlet.textSync('Weather', {
      font: 'Big',
      horizontalLayout: 'default',
      verticalLayout: 'default'
    });
    
    console.log(chalk.cyan(banner));
    console.log(chalk.cyan.bold('═══════════════════════════════════════════'));
    console.log(chalk.cyan.bold('         Weather Dashboard CLI'));
    console.log(chalk.cyan.bold('═══════════════════════════════════════════'));
    console.log();
  }

  showCurrentWeather(weather) {
    console.log();
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold(`  📍 ${weather.location}, ${weather.country}`));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();

    const icon = this.weatherIcons[weather.icon] || '🌡️';
    console.log(chalk.yellow.bold(`  ${icon}  ${weather.description.toUpperCase()}`));
    console.log();

    console.log(chalk.white('  Temperature:    ') + chalk.cyan.bold(weather.temperature));
    console.log(chalk.white('  Feels Like:     ') + chalk.cyan.bold(weather.feelsLike));
    console.log(chalk.white('  Humidity:       ') + chalk.cyan.bold(weather.humidity));
    console.log(chalk.white('  Pressure:       ') + chalk.cyan.bold(weather.pressure));
    console.log(chalk.white('  Wind Speed:     ') + chalk.cyan.bold(weather.windSpeed));
    console.log(chalk.white('  Wind Direction: ') + chalk.cyan.bold(weather.windDirection));
    console.log(chalk.white('  Visibility:     ') + chalk.cyan.bold(weather.visibility));
    console.log(chalk.white('  Cloud Cover:    ') + chalk.cyan.bold(weather.clouds));
    console.log();

    console.log(chalk.white('  🌅 Sunrise:  ') + chalk.cyan.bold(weather.sunrise));
    console.log(chalk.white('  🌇 Sunset:   ') + chalk.cyan.bold(weather.sunset));
    console.log();

    console.log(chalk.gray(`  Last updated: ${new Date(weather.timestamp).toLocaleString()}`));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }

  showForecast(forecast) {
    console.log();
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold(`  📊 5-Day Forecast for ${forecast.location}`));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();

    forecast.forecasts.forEach((day, index) => {
      const icon = this.weatherIcons[day.icon] || '🌡️';
      
      if (index > 0) {
        console.log(chalk.gray('──────────────────────────────────────────────────'));
      }
      
      console.log();
      console.log(chalk.yellow.bold(`  📅 ${day.date}`));
      console.log(chalk.cyan.bold(`     ${icon} ${day.description}`));
      console.log();
      console.log(chalk.white('     Temperature: ') + chalk.cyan.bold(`${day.tempMin} - ${day.tempMax}`));
      console.log(chalk.white('     Avg Temp:    ') + chalk.cyan.bold(day.avgTemp));
      console.log(chalk.white('     Humidity:    ') + chalk.cyan.bold(day.humidity));
      console.log(chalk.white('     Wind Speed:  ') + chalk.cyan.bold(day.windSpeed));
      console.log();
    });

    console.log(chalk.gray('──────────────────────────────────────────────────'));
    console.log();
    console.log(chalk.gray(`Last updated: ${new Date(forecast.timestamp).toLocaleString()}`));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }

  showLocations(locations) {
    console.log();
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold(`  🔍 Found ${locations.length} location(s)`));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();

    if (locations.length === 0) {
      console.log(chalk.yellow('  No locations found. Try a different search term.'));
      console.log();
      return;
    }

    locations.forEach((loc, index) => {
      const state = loc.state ? `, ${loc.state}` : '';
      const number = (index + 1).toString().padStart(2, ' ');
      console.log(chalk.white(`  ${number}. `) + chalk.cyan.bold(`${loc.name}${state}, ${loc.country}`));
      console.log(chalk.gray(`     📍 Coordinates: ${loc.lat.toFixed(4)}, ${loc.lon.toFixed(4)}`));
      console.log();
    });

    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
    console.log(chalk.gray('  Tip: Use the full location name for weather queries'));
    console.log(chalk.gray('  Example: weather current "New York, US"'));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }

  showError(message) {
    console.log();
    console.log(chalk.red.bold('═'.repeat(50)));
    console.log(chalk.red.bold('  ❌ Error'));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
    console.log(chalk.red(`  ${message}`));
    console.log();
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }

  showSuccess(message) {
    console.log();
    console.log(chalk.green.bold('═'.repeat(50)));
    console.log(chalk.green.bold('  ✅ Success'));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
    console.log(chalk.green(`  ${message}`));
    console.log();
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }

  showConfig(config) {
    console.log();
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold('  ⚙️  Current Configuration'));
    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();

    const maskedApiKey = config.apiKey ? `${config.apiKey.substring(0, 4)}...${config.apiKey.slice(-4)}` : 'Not set';
    
    console.log(chalk.white('  API Key:        ') + (config.apiKey ? chalk.cyan(maskedApiKey) : chalk.red('Not set')));
    console.log(chalk.white('  Units:          ') + chalk.cyan(config.units));
    console.log(chalk.white('  Language:       ') + chalk.cyan(config.language));
    console.log(chalk.white('  Default City:   ') + (config.defaultLocation ? chalk.cyan(config.defaultLocation) : chalk.gray('Not set')));
    console.log(chalk.white('  Forecast Days:  ') + chalk.cyan(config.forecastDays.toString()));
    console.log(chalk.white('  Config File:    ') + chalk.gray(config._configPath));
    console.log();

    if (!config.apiKey) {
      console.log(chalk.yellow('  ⚠️  API key is not set!'));
      console.log(chalk.yellow('  Get your free API key at: https://openweathermap.org/api'));
      console.log(chalk.yellow('  Then run: weather-dashboard config --set-api-key YOUR_API_KEY'));
      console.log();
    }

    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }

  showHelp() {
    this.showBanner();
    
    console.log(chalk.white.bold('📖 Usage:'));
    console.log(chalk.cyan('  weather-dashboard <command> [options]'));
    console.log();

    console.log(chalk.white.bold('📋 Available Commands:'));
    console.log();
    
    console.log(chalk.cyan('  weather current [location]'));
    console.log(chalk.gray('     Get current weather for a location'));
    console.log(chalk.gray('     Example: weather-dashboard current "London, UK"'));
    console.log(chalk.gray('     Example: weather-dashboard current "New York"'));
    console.log();

    console.log(chalk.cyan('  weather-dashboard forecast [location]'));
    console.log(chalk.gray('     Get 5-day forecast for a location'));
    console.log(chalk.gray('     Example: weather-dashboard forecast "Tokyo, JP"'));
    console.log();

    console.log(chalk.cyan('  weather-dashboard search <query>'));
    console.log(chalk.gray('     Search for locations'));
    console.log(chalk.gray('     Example: weather-dashboard search "Paris"'));
    console.log();

    console.log(chalk.cyan('  weather-dashboard config [options]'));
    console.log(chalk.gray('     Manage configuration'));
    console.log(chalk.gray('     Options:'));
    console.log(chalk.gray('       --set-api-key <key>     Set OpenWeatherMap API key'));
    console.log(chalk.gray('       --set-units <units>     Set temperature units (metric/imperial/standard)'));
    console.log(chalk.gray('       --set-language <lang>   Set language code'));
    console.log(chalk.gray('       --set-default-location  Set default location'));
    console.log(chalk.gray('       --show                  Show current configuration'));
    console.log(chalk.gray('       --reset                 Reset to defaults'));
    console.log();

    console.log(chalk.cyan('  weather-dashboard --version'));
    console.log(chalk.gray('     Show version information'));
    console.log();

    console.log(chalk.cyan('  weather-dashboard --help'));
    console.log(chalk.gray('     Show this help message'));
    console.log();

    console.log(chalk.white.bold('🌐 Environment Variables:'));
    console.log();
    console.log(chalk.gray('  WEATHER_API_KEY         Your OpenWeatherMap API key'));
    console.log(chalk.gray('  WEATHER_UNITS           Temperature units (metric/imperial/standard)'));
    console.log(chalk.gray('  WEATHER_LANGUAGE        Language code (e.g., en, es, fr)'));
    console.log();

    console.log(chalk.white.bold('📝 Notes:'));
    console.log();
    console.log(chalk.gray('  • Get a free API key at https://openweathermap.org/api'));
    console.log(chalk.gray('  • Default location is used when no location is provided'));
    console.log(chalk.gray('  • Configuration is stored in ~/.weather-dashboard/config.json'));
    console.log();

    console.log(chalk.white.bold('═'.repeat(50)));
    console.log();
  }
}

// Export singleton instance
module.exports = new DisplayUtils();

// Export class for testing
module.exports.DisplayUtils = DisplayUtils;
