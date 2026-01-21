const chalk = require('chalk');

class DisplayUtils {
  constructor(configManager) {
    this.configManager = configManager;
  }

  displayCurrentWeather(weatherData, locationName, units) {
    const { location, current, units: unitInfo } = weatherData;

    // Location header
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold('  📍 ' + location.name + (location.country ? ', ' + location.country : '')));
    console.log(chalk.cyan.bold('═'.repeat(50)));

    // Main weather display
    console.log();
    console.log(chalk.white.bold('  Current Weather'));
    console.log(chalk.gray('  ' + new Date().toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })));
    console.log();

    // Temperature
    console.log(chalk.cyan('  🌡️  Temperature: ') + chalk.white.bold(Math.round(current.temperature) + unitInfo.temperature));
    console.log(chalk.cyan('  🤒 Feels Like:  ') + chalk.white.bold(Math.round(current.feelsLike) + unitInfo.temperature));
    console.log();

    // Weather description
    console.log(chalk.white('  ☁️  Condition: ') + chalk.yellow(current.weather.main) + ' - ' + this.capitalizeFirst(current.weather.description));
    console.log();

    // Additional details
    console.log(chalk.cyan('  💧 Humidity:    ') + chalk.white(current.humidity + '%'));
    console.log(chalk.cyan('  📊 Pressure:    ') + chalk.white(current.pressure + ' hPa'));
    console.log(chalk.cyan('  💨 Wind:        ') + chalk.white(current.windSpeed + ' ' + unitInfo.speed + ' ' + current.windDirection));
    console.log(chalk.cyan('  👁️  Visibility:   ') + chalk.white((current.visibility / 1000).toFixed(1) + ' km'));
    console.log(chalk.cyan('  ☁️  Clouds:       ') + chalk.white(current.clouds + '%'));

    if (current.sunrise && current.sunset) {
      console.log();
      console.log(chalk.cyan('  🌅 Sunrise:     ') + chalk.white(current.sunrise.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })));
      console.log(chalk.cyan('  🌇 Sunset:      ') + chalk.white(current.sunset.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })));
    }

    console.log();
    console.log(chalk.cyan.bold('═'.repeat(50)));
  }

  displayForecast(forecastData, locationName, units) {
    const { location, forecast, units: unitInfo } = forecastData;

    // Location header
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold('  📍 ' + location.name + (location.country ? ', ' + location.country : '') + ' - 5 Day Forecast'));
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log();

    forecast.forEach((day, index) => {
      if (index > 0) {
        console.log(chalk.gray('─'.repeat(50)));
      }

      // Day header
      const dayName = day.date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' });
      console.log(chalk.white.bold('  📅 ' + dayName));
      console.log();

      // Weather icon and condition
      const weatherIcon = this.getWeatherEmoji(day.weather.main);
      console.log(chalk.cyan('  ' + weatherIcon + ' ') + chalk.yellow(day.weather.main) + ' - ' + this.capitalizeFirst(day.weather.description));
      console.log();

      // Temperature range
      console.log(chalk.cyan('  🌡️  High: ') + chalk.white.bold(Math.round(day.tempMax) + unitInfo.temperature) +
                 chalk.cyan('  Low:  ') + chalk.white.bold(Math.round(day.tempMin) + unitInfo.temperature));
      console.log(chalk.cyan('  📊 Avg:  ') + chalk.white(Math.round(day.tempAvg) + unitInfo.temperature));
      console.log();

      // Additional details
      console.log(chalk.cyan('  💧 Humidity: ') + chalk.white(day.humidity + '%'));
      console.log(chalk.cyan('  💨 Wind:     ') + chalk.white(day.windSpeed + ' ' + unitInfo.speed + ' ' + day.windDirection));
      console.log();

      // Hourly preview (first 4 hours)
      if (day.hourly && day.hourly.length > 0) {
        console.log(chalk.gray('  Hourly Preview:'));
        const previewHours = day.hourly.slice(0, 4);
        const hourStrings = previewHours.map(h => {
          const time = h.time.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
          return chalk.cyan('  ') + time + ' ' + Math.round(h.temperature) + unitInfo.temperature;
        });
        console.log(hourStrings.join(chalk.gray(' | ')));
      }
    });

    console.log();
    console.log(chalk.cyan.bold('═'.repeat(50)));
  }

  displaySearchResults(locations, query) {
    if (!locations || locations.length === 0) {
      console.log(chalk.yellow('  No locations found for "' + query + '"'));
      console.log(chalk.gray('  Try a different search term or check spelling.'));
      return;
    }

    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold('  🔍 Search Results for "' + query + '"'));
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log();

    locations.forEach((location, index) => {
      const locationStr = location.state
        ? `${location.name}, ${location.state}, ${location.country}`
        : `${location.name}, ${location.country}`;

      console.log(chalk.white.bold('  ' + (index + 1) + '. ' + locationStr));
      console.log(chalk.gray('     📍 Coordinates: ' + location.lat.toFixed(4) + ', ' + location.lon.toFixed(4)));
      console.log();
    });

    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log(chalk.gray('  Use ' + chalk.cyan('weather-dashboard current "Location Name"') + ' to get weather'));
  }

  displayConfiguration(config) {
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log(chalk.cyan.bold('  ⚙️  Current Configuration'));
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log();

    // API Key status
    if (config.apiKey) {
      console.log(chalk.green('  ✅ API Key:        ') + chalk.white('********' + config.apiKey.slice(-4)));
    } else {
      console.log(chalk.red('  ❌ API Key:        ') + chalk.white('Not set'));
      console.log(chalk.gray('     Get a free API key at https://openweathermap.org/api'));
    }

    console.log();

    // Default location
    console.log(chalk.cyan('  📍 Default Location: ') + chalk.white(config.defaultLocation || 'Not set'));

    // Units
    const unitNames = {
      metric: 'Metric (°C, m/s)',
      imperial: 'Imperial (°F, mph)',
      standard: 'Standard (K, m/s)'
    };
    console.log(chalk.cyan('  📊 Default Units:    ') + chalk.white(unitNames[config.units] || config.units));

    // Language
    console.log(chalk.cyan('  🌐 Language:        ') + chalk.white(config.language || 'en'));

    console.log();
    console.log(chalk.cyan.bold('═'.repeat(50)));
    console.log();
    console.log(chalk.gray('  To update configuration, use:'));
    console.log(chalk.cyan('    weather-dashboard config --api-key YOUR_API_KEY'));
    console.log(chalk.cyan('    weather-dashboard config --set-default-location "Your City"'));
    console.log(chalk.cyan('    weather-dashboard config --units metric'));
  }

  handleError(error, context) {
    console.log();
    console.log(chalk.red.bold('═'.repeat(50)));
    console.log(chalk.red.bold('  ❌ Error'));
    console.log(chalk.red.bold('═'.repeat(50)));
    console.log();

    // Determine error type and provide helpful message
    if (error.message.includes('API key') || error.message.includes('401')) {
      console.log(chalk.red('  ' + error.message));
      console.log();
      console.log(chalk.gray('  To fix this:'));
      console.log(chalk.cyan('    1. Get a free API key at https://openweathermap.org/api'));
      console.log(chalk.cyan('    2. Set it using: weather-dashboard config --api-key YOUR_KEY'));
    } else if (error.message.includes('Location not found') || error.message.includes('404')) {
      console.log(chalk.red('  ' + error.message));
      console.log();
      console.log(chalk.gray('  To fix this:'));
      console.log(chalk.cyan('    1. Try a different search term'));
      console.log(chalk.cyan('    2. Include the country code (e.g., "London, GB")'));
      console.log(chalk.cyan('    3. Use the search command: weather-dashboard search "Your City"'));
    } else if (error.message.includes('rate limit') || error.message.includes('429')) {
      console.log(chalk.red('  ' + error.message));
      console.log();
      console.log(chalk.gray('  To fix this:'));
      console.log(chalk.cyan('    1. Wait a moment and try again'));
      console.log(chalk.cyan('    2. OpenWeatherMap free tier has limits'));
    } else if (error.message.includes('Network') || error.message.includes('ECONNREFUSED')) {
      console.log(chalk.red('  ' + error.message));
      console.log();
      console.log(chalk.gray('  To fix this:'));
      console.log(chalk.cyan('    1. Check your internet connection'));
      console.log(chalk.cyan('    2. Try again later'));
    } else if (error.message.includes('not configured') || error.message.includes('not set')) {
      console.log(chalk.red('  ' + error.message));
      console.log();
      console.log(chalk.gray('  To fix this:'));
      console.log(chalk.cyan('    weather-dashboard config --api-key YOUR_API_KEY'));
    } else {
      console.log(chalk.red('  An error occurred while fetching ' + context + ':'));
      console.log(chalk.red('  ' + error.message));
    }

    console.log();
    console.log(chalk.red.bold('═'.repeat(50)));
  }

  capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  getWeatherEmoji(weatherMain) {
    const weatherEmojis = {
      'Clear': '☀️',
      'Clouds': '☁️',
      'Rain': '🌧️',
      'Drizzle': '🌦️',
      'Thunderstorm': '⛈️',
      'Snow': '❄️',
      'Mist': '🌫️',
      'Fog': '🌫️',
      'Haze': '🌫️',
      'Dust': '🌪️',
      'Sand': '🌪️',
      'Ash': '🌋',
      'Squall': '🌬️',
      'Tornado': '🌪️'
    };
    return weatherEmojis[weatherMain] || '🌡️';
  }
}

module.exports = DisplayUtils;
