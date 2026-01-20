const chalk = require('chalk');

class Formatter {
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

  formatCurrentWeather(weatherData) {
    const { location, country, current, units } = weatherData;
    const temp = current.main.temp;
    const feelsLike = current.main.feels_like;
    const description = current.weather[0].description;
    const icon = this.getWeatherIcon(current.weather[0].icon);
    const humidity = current.main.humidity;
    const pressure = current.main.pressure;
    const wind = current.wind;
    const unitSymbol = this.getUnitSymbol(units);

    console.log();
    console.log(chalk.bold.blue(`📍 ${location}, ${country}`));
    console.log(chalk.gray('─'.repeat(50)));
    
    console.log(`${icon} ${this.getTemperatureColor(temp, units)}${Math.round(temp)}${unitSymbol}${chalk.reset}`);
    console.log(chalk.gray(`Feels like: ${Math.round(feelsLike)}${unitSymbol}`));
    console.log(chalk.gray(description.charAt(0).toUpperCase() + description.slice(1)));
    
    console.log();
    console.log(chalk.yellow('📊 Details:'));
    console.log(`  💧 Humidity: ${humidity}%`);
    console.log(`  🌡️  Pressure: ${pressure} hPa`);
    
    if (wind) {
      const windSpeed = wind.speed || 0;
      const windDirection = this.getWindDirection(wind.deg || 0);
      const windUnit = units === 'imperial' ? 'mph' : 'm/s';
      console.log(`  💨 Wind: ${windSpeed} ${windUnit} ${windDirection}`);
      
      if (wind.gust) {
        console.log(`    Gusts up to: ${wind.gust} ${windUnit}`);
      }
    }

    if (current.sys) {
      const sunrise = new Date(current.sys.sunrise * 1000);
      const sunset = new Date(current.sys.sunset * 1000);
      console.log(`  🌅 Sunrise: ${sunrise.toLocaleTimeString()}`);
      console.log(`  🌇 Sunset: ${sunset.toLocaleTimeString()}`);
    }

    console.log();
  }

  formatForecast(forecastData) {
    const { location, country, forecasts, units } = forecastData;
    const unitSymbol = this.getUnitSymbol(units);

    console.log();
    console.log(chalk.bold.blue(`📍 ${location}, ${country} - Forecast`));
    console.log(chalk.gray('─'.repeat(50)));

    forecasts.forEach((day, index) => {
      const date = new Date(day.date);
      const dateStr = date.toLocaleDateString('en-US', { 
        weekday: 'short', month: 'short', day: 'numeric' 
      });
      
      const icon = this.getWeatherIcon(day.weather[0].icon);
      const description = day.weather[0].description;
      
      console.log();
      console.log(chalk.bold(`${dateStr} ${icon}`));
      console.log(chalk.gray(description));
      
      const minTemp = this.getTemperatureColor(day.temp_min, units);
      const maxTemp = this.getTemperatureColor(day.temp_max, units);
      console.log(`${minTemp}${Math.round(day.temp_min)}${unitSymbol} / ${maxTemp}${Math.round(day.temp_max)}${unitSymbol}${chalk.reset}`);
      
      console.log(`💧 ${day.humidity}%  💨 ${day.wind?.speed || 0} ${units === 'imperial' ? 'mph' : 'm/s'}`);
      
      const keyHours = [0, 3, 6];
      if (day.forecasts.length > 0) {
        console.log(chalk.gray('Hourly:'));
        keyHours.forEach(hourIndex => {
          if (day.forecasts[hourIndex]) {
            const hourly = day.forecasts[hourIndex];
            const time = new Date(hourly.dt * 1000);
            const timeStr = time.toLocaleTimeString('en-US', { 
              hour: 'numeric', hour12: false 
            });
            const temp = this.getTemperatureColor(hourly.main.temp, units);
            const hourlyIcon = this.getWeatherIcon(hourly.weather[0].icon);
            console.log(`  ${timeStr}: ${hourlyIcon} ${temp}${Math.round(hourly.main.temp)}${unitSymbol}${chalk.reset}`);
          }
        });
      }
    });

    console.log();
  }

  formatLocationSearch(locations) {
    if (!locations || locations.length === 0) {
      console.log(chalk.yellow('No locations found.'));
      return;
    }

    console.log();
    console.log(chalk.bold.blue('🔍 Search Results:'));
    console.log(chalk.gray('─'.repeat(50)));

    locations.forEach((location, index) => {
      const locationStr = location.state 
        ? `${location.name}, ${location.state}, ${location.country}`
        : `${location.name}, ${location.country}`;
      
      console.log(`${chalk.cyan((index + 1).toString())}. ${locationStr}`);
      console.log(`   ${chalk.gray(`Coordinates: ${location.coordinates.lat.toFixed(4)}, ${location.coordinates.lon.toFixed(4)}`)}`);
    });

    console.log();
    console.log(chalk.gray('Tip: Use "weather current <location>" to get weather for any of these locations.'));
    console.log();
  }

  formatConfig(config) {
    console.log();
    console.log(chalk.bold.blue('⚙️  Configuration:'));
    console.log(chalk.gray('─'.repeat(30)));
    
    console.log(`API Key: ${config.apiKey === 'NOT SET' ? chalk.red('NOT SET') : chalk.green('SET')}`);
    console.log(`Units: ${chalk.cyan(config.units)}`);
    console.log(`Config File: ${chalk.gray(config.configFile)}`);
    
    console.log();
    console.log(chalk.yellow('To set API key:'));
    console.log(chalk.gray('1. Get a free API key from https://openweathermap.org/api'));
    console.log(chalk.gray('2. Set environment variable: export OPENWEATHER_API_KEY=your_key'));
    console.log(chalk.gray('3. Or use: weather config --set apiKey=your_key'));
    console.log();
  }

  getWeatherIcon(iconCode) {
    return this.weatherIcons[iconCode] || '🌡️';
  }

  getTemperatureColor(temp, units) {
    const celsius = units === 'imperial' ? (temp - 32) * 5/9 : temp;
    
    if (celsius <= 0) return chalk.cyan;
    if (celsius <= 10) return chalk.blue;
    if (celsius <= 20) return chalk.green;
    if (celsius <= 30) return chalk.yellow;
    return chalk.red;
  }

  getUnitSymbol(units) {
    switch (units) {
      case 'imperial': return '°F';
      case 'kelvin': return 'K';
      case 'metric':
      default: return '°C';
    }
  }

  getWindDirection(degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    const index = Math.round(degrees / 22.5) % 16;
    return directions[index];
  }

  formatError(message) {
    return chalk.red(`❌ Error: ${message}`);
  }

  formatSuccess(message) {
    return chalk.green(`✅ ${message}`);
  }
}

module.exports = Formatter;