# Weather Dashboard CLI

A sophisticated command-line weather application that provides real-time weather data, forecasts, and location search capabilities using the OpenWeatherMap API.

![Weather Dashboard CLI](https://via.placeholder.com/800x200/0077b6/ffffff?text=Weather+Dashboard+CLI)

## Features

🌤️ **Current Weather** - Get real-time weather conditions for any location worldwide

📊 **5-Day Forecast** - Extended weather predictions with hourly breakdowns

🔍 **Location Search** - Search and find cities around the world

⚙️ **Configuration Management** - Customizable settings for units, language, and defaults

🌍 **Multi-Unit Support** - Metric, Imperial, and Standard (Kelvin) temperature units

🎨 **Beautiful Output** - Colorful, formatted display with weather icons

🛡️ **Robust Error Handling** - Clear, helpful error messages for troubleshooting

## Installation

### Prerequisites

- Node.js 16.0.0 or higher
- npm (comes with Node.js)
- OpenWeatherMap API key (free)

### Install from Source

1. **Clone the repository**

   ```bash
   git clone https://github.com/ralphloop/weather-dashboard-cli.git
   cd weather-dashboard-cli
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Link the CLI globally**
   ```bash
   npm link
   ```

### Install as npm Package

```bash
# Install globally
npm install -g weather-dashboard-cli

# Or install locally and use npx
npx weather-dashboard-cli
```

## Quick Start

### 1. Get Your API Key

1. Sign up for a free account at [OpenWeatherMap](https://openweathermap.org/)
2. Navigate to [API Keys section](https://home.openweathermap.org/api_keys)
3. Generate a new API key
4. Copy your API key

### 2. Configure Your API Key

**Method 1: Using the CLI**

```bash
weather-dashboard config --set-api-key YOUR_API_KEY_HERE
```

**Method 2: Environment Variable**

```bash
# Linux/macOS
export WEATHER_API_KEY=YOUR_API_KEY_HERE

# Windows (Command Prompt)
set WEATHER_API_KEY=YOUR_API_KEY_HERE

# Windows (PowerShell)
$env:WEATHER_API_KEY="YOUR_API_KEY_HERE"
```

**Method 3: Configuration File**

```bash
# Your config file is stored at:
~/.weather-dashboard/config.json
```

### 3. Start Using!

```bash
# Get current weather for a city
weather-dashboard current "London, UK"

# Get 5-day forecast
weather-dashboard forecast "New York, US"

# Search for locations
weather-dashboard search "Paris"

# Show current configuration
weather-dashboard config --show
```

## Usage

### Commands

#### Current Weather

Get real-time weather conditions for a location:

```bash
# Basic usage
weather-dashboard current "London"

# With country code
weather-dashboard current "Tokyo, JP"

# Use your default location
weather-dashboard current
```

**Example Output:**

```
═══════════════════════════════════════════
  📍 London, GB
═══════════════════════════════════════════

  ☁️  CLOUDY

  Temperature:    15°C
  Feels Like:     14°C
  Humidity:       70%
  Pressure:       1013 hPa
  Wind Speed:     3 m/s
  Wind Direction: S
  Visibility:     10.0 km
  Cloud Cover:    75%

  🌅 Sunrise:  06:30:00 AM
  🌇 Sunset:   05:45:00 PM

  Last updated: 1/15/2024, 10:30:00 AM
═══════════════════════════════════════════
```

#### Weather Forecast

Get a 5-day weather forecast with hourly details:

```bash
# Basic usage
weather-dashboard forecast "Paris, FR"

# Use default location
weather-dashboard forecast
```

**Example Output:**

```
═══════════════════════════════════════════
  📊 5-Day Forecast for Paris
═══════════════════════════════════════════

  📅 1/15/2024
     ⛅ Partly cloudy
     Temperature: 10°C - 15°C
     Avg Temp:    13°C
     Humidity:    60%
     Wind Speed:  2.5 m/s

──────────────────────────────────────────────────

  📅 1/16/2024
     ☁️ Cloudy
     Temperature: 8°C - 12°C
     Avg Temp:    10°C
     Humidity:    70%
     Wind Speed:  3.0 m/s

Last updated: 1/15/2024, 10:00:00 AM
═══════════════════════════════════════════
```

#### Location Search

Search for cities around the world:

```bash
# Search for a city
weather-dashboard search "San Francisco"

# Search with country
weather-dashboard search "Berlin, DE"
```

**Example Output:**

```
═══════════════════════════════════════════
  🔍 Found 2 location(s)
═══════════════════════════════════════════

  1. San Francisco, CA, US
     📍 Coordinates: 37.7749, -122.4194

  2. San Francisco, TX, US
     📍 Coordinates: 30.4278, -97.7654

═══════════════════════════════════════════
  Tip: Use the full location name for weather queries
  Example: weather current "New York, US"
═══════════════════════════════════════════
```

#### Configuration Management

Manage your weather dashboard settings:

```bash
# Show current configuration
weather-dashboard config --show

# Set API key
weather-dashboard config --set-api-key YOUR_API_KEY

# Set temperature units (metric/imperial/standard)
weather-dashboard config --set-units metric

# Set language code
weather-dashboard config --set-language en

# Set default location
weather-dashboard config --set-default-location "London, UK"

# Set number of forecast days (1-8)
weather-dashboard config --set-forecast-days 7

# Reset to defaults
weather-dashboard config --reset
```

**Example Configuration:**

```
═══════════════════════════════════════════
  ⚙️  Current Configuration
═══════════════════════════════════════════

  API Key:        a1b2...9z8y
  Units:          metric
  Language:       en
  Default City:   London, UK
  Forecast Days:  5
  Config File:    /home/user/.weather-dashboard/config.json

═══════════════════════════════════════════
```

#### Help

Show help information and available commands:

```bash
weather-dashboard help
```

## Configuration Options

### Temperature Units

| Unit       | Symbol | Description       |
| ---------- | ------ | ----------------- |
| `metric`   | °C     | Celsius (default) |
| `imperial` | °F     | Fahrenheit        |
| `standard` | K      | Kelvin            |

### Language Codes

The application supports multiple languages. Common codes:

| Code | Language          |
| ---- | ----------------- |
| `en` | English (default) |
| `es` | Spanish           |
| `fr` | French            |
| `de` | German            |
| `it` | Italian           |
| `pt` | Portuguese        |
| `ru` | Russian           |
| `ja` | Japanese          |
| `zh` | Chinese           |

### Environment Variables

Override configuration with environment variables:

| Variable                  | Description                                  |
| ------------------------- | -------------------------------------------- |
| `WEATHER_API_KEY`         | Your OpenWeatherMap API key                  |
| `WEATHER_UNITS`           | Temperature units (metric/imperial/standard) |
| `WEATHER_LANGUAGE`        | Language code                                |
| `WEATHER_DEFAULTLOCATION` | Default location                             |
| `WEATHER_FORECASTDAYS`    | Number of forecast days (1-8)                |

**Example:**

```bash
WEATHER_API_KEY=your-key WEATHER_UNITS=imperial weather-dashboard current "Miami"
```

## API Information

### OpenWeatherMap API

This application uses the following OpenWeatherMap APIs:

- **Current Weather Data**: `GET /data/2.5/weather`
- **5-Day Forecast**: `GET /data/2.5/forecast`
- **Geocoding API**: `GET /geo/1.0/direct`

### Rate Limits

Free API tier includes:

- 60 calls/minute
- 1,000,000 calls/month

## Development

### Project Structure

```
weather-dashboard-cli/
├── bin/
│   └── weather-dashboard.js    # CLI entry point
├── src/
│   ├── cli.js                  # Commander.js CLI setup
│   ├── index.js                # Main application entry
│   ├── config/
│   │   └── index.js            # Configuration management
│   ├── services/
│   │   └── weather.js          # Weather API service
│   └── utils/
│       └── display.js          # Display utilities
├── tests/
│   ├── config.test.js          # Config tests
│   ├── weather.test.js         # Weather service tests
│   └── display.test.js         # Display tests
├── package.json
└── jest.config.js
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run tests in watch mode
npm run test:watch
```

### Linting

```bash
# Check code style
npm run lint

# Auto-fix issues
npm run lint:fix
```

### Build and Package

```bash
# Build (if needed)
npm run build

# Package for distribution
npm pack
```

## Troubleshooting

### Common Issues

#### "API key not configured"

- Run `weather-dashboard config --set-api-key YOUR_API_KEY`
- Or set the `WEATHER_API_KEY` environment variable

#### "Network error: Unable to reach OpenWeatherMap API"

- Check your internet connection
- Verify the OpenWeatherMap service is available
- Ensure no firewall is blocking the request

#### "Location not found"

- Try a more specific location with country code
- Example: `weather-dashboard search "Springfield, US"`
- Use the search command to find the exact location name

#### "API rate limit exceeded"

- Wait a moment before retrying
- Consider upgrading to a paid API plan for higher limits

### Getting Help

```bash
# Show help
weather-dashboard --help

# Show version
weather-dashboard --version
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenWeatherMap](https://openweathermap.org/) for providing the weather API
- [Commander.js](https://github.com/tj/commander.js/) for the CLI framework
- [Chalk](https://github.com/chalk/chalk) for beautiful terminal colors
- [Figlet](http://www.figlet.org/) for ASCII art banners

## Version History

- **1.0.0** - Initial release
  - Current weather display
  - 5-day forecast
  - Location search
  - Configuration management
  - Multi-language support
  - Unit conversion (metric/imperial/standard)
  - Comprehensive error handling
  - Unit tests

## Support

- 📧 Email: support@weather-dashboard-cli.com
- 🐛 Issues: [GitHub Issues](https://github.com/ralphloop/weather-dashboard-cli/issues)
- 📖 Documentation: [Wiki](https://github.com/ralphloop/weather-dashboard-cli/wiki)

---

**Made with ❤️ by RalphLoop**
