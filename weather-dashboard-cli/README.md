# Weather Dashboard CLI

A powerful and user-friendly command-line tool for accessing real-time weather data and forecasts. Built with Node.js, this tool provides instant weather information for any location worldwide using the OpenWeatherMap API.

![Weather Dashboard CLI](https://via.placeholder.com/800x400?text=Weather+Dashboard+CLI)

## Features

- **Real-time Weather**: Get current weather conditions for any location worldwide
- **5-Day Forecast**: Detailed forecast with hourly breakdowns
- **Location Search**: Search for cities and towns globally
- **Multiple Units**: Support for metric, imperial, and standard units
- **Persistent Configuration**: Save your preferences across sessions
- **Beautiful Display**: Colorful, formatted output with weather emojis
- **Error Handling**: Helpful error messages with suggested solutions

## Installation

### Prerequisites

- Node.js 16.0.0 or higher
- npm (usually comes with Node.js)
- OpenWeatherMap API key (free)

### Quick Install

```bash
# Clone the repository
git clone https://github.com/ralphloop/weather-dashboard-cli.git
cd weather-dashboard-cli

# Install dependencies
npm install

# Make the CLI executable
chmod +x bin/weather-dashboard.js

# Link globally (optional)
npm link
```

### Global Installation

```bash
# Install globally
npm install -g /path/to/weather-dashboard-cli

# Or publish to npm and install
npm publish --access public
npm install -g weather-dashboard-cli
```

## Getting Started

### 1. Get Your API Key

1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Navigate to "My API Keys"
4. Copy your API key

> **Note**: New API keys may take 10-15 minutes to activate.

### 2. Configure Your API Key

```bash
# Set your API key
weather-dashboard config --api-key YOUR_API_KEY

# Verify configuration
weather-dashboard config --show
```

### 3. Start Using

```bash
# Get current weather
weather-dashboard current "New York, US"

# Get 5-day forecast
weather-dashboard forecast "London, GB"

# Search for a location
weather-dashboard search "Paris"

# Set default location (optional)
weather-dashboard config --set-default-location "Your City"
```

## Commands

### `weather-dashboard current [location]`

Get current weather conditions for a location.

```bash
# Basic usage
weather-dashboard current "New York, US"

# With custom units
weather-dashboard current "Tokyo, JP" --units metric
weather-dashboard current "Los Angeles, US" --units imperial

# Uses default location if set
weather-dashboard current
```

**Options:**

- `-u, --units <type>` - Temperature units: `metric` (°C), `imperial` (°F), or `standard` (K)

### `weather-dashboard forecast [location]`

Get a 5-day weather forecast with hourly breakdowns.

```bash
# Basic usage
weather-dashboard forecast "London, GB"

# With custom units
weather-dashboard forecast "Berlin, DE" --units metric
weather-dashboard forecast "Chicago, US" --units imperial

# Uses default location if set
weather-dashboard forecast
```

**Options:**

- `-u, --units <type>` - Temperature units: `metric` (°C), `imperial` (°F), or `standard` (K)

### `weather-dashboard search <query>`

Search for locations worldwide.

```bash
# Search for a city
weather-dashboard search "Paris"

# Search with state/country
weather-dashboard search "Springfield"

# Get more results
weather-dashboard search "San"
```

### `weather-dashboard config`

Manage application settings.

```bash
# Show current configuration
weather-dashboard config --show

# Set API key
weather-dashboard config --api-key YOUR_API_KEY

# Set default location
weather-dashboard config --set-default-location "New York, US"

# Set default units
weather-dashboard config --units metric
weather-dashboard config --units imperial
weather-dashboard config --units standard
```

## Configuration

The configuration is stored in `~/.weather-dashboard/config.json` and includes:

```json
{
  "apiKey": "your-api-key",
  "units": "metric",
  "defaultLocation": "Your City",
  "language": "en"
}
```

### Environment Variables

You can also use environment variables:

| Variable                   | Description            | Default  |
| -------------------------- | ---------------------- | -------- |
| `WEATHER_API_KEY`          | OpenWeatherMap API key | (empty)  |
| `WEATHER_UNITS`            | Default units          | `metric` |
| `WEATHER_DEFAULT_LOCATION` | Default location       | (empty)  |
| `WEATHER_LANGUAGE`         | Language code          | `en`     |

Example:

```bash
export WEATHER_API_KEY="your-api-key"
export WEATHER_UNITS="imperial"
```

## Examples

### Current Weather

```
$ weather-dashboard current "San Francisco, US"

═══════════════════════════════════════════════════════════
  📍 San Francisco, US
═══════════════════════════════════════════════════════════

  Current Weather
  Wednesday, January 15, 2025

  🌡️  Temperature:  18°C
  🤒 Feels Like:   17°C

  ☁️  Condition:  Clear - clear sky

  💧 Humidity:    65%
  📊 Pressure:    1013 hPa
  💨 Wind:        3.5 m/s W
  👁️  Visibility:  10.0 km
  ☁️  Clouds:       0%

  🌅 Sunrise:     07:26 AM
  🌇 Sunset:      05:17 PM
```

### 5-Day Forecast

```
$ weather-dashboard forecast "London, GB"

═══════════════════════════════════════════════════════════
  📍 London, GB - 5 Day Forecast
═══════════════════════════════════════════════════════════

  📅 Wednesday, Jan 15
  ☀️ Clear - clear sky

  🌡️ High: 12°C  Low:  8°C
  📊 Avg:  10°C

  💧 Humidity: 75%
  💨 Wind:     4.2 m/s SW

  Hourly Preview:
  12:00 PM 10°C | 03:00 PM 12°C | 06:00 PM 9°C | 09:00 PM 8°C

──────────────────────────────────────────
  📅 Thursday, Jan 16
  🌧️ Rain - light rain

  🌡️ High: 11°C  Low:  7°C
  📊 Avg:  9°C

  💧 Humidity: 82%
  💨 Wind:     5.1 m/s S

  Hourly Preview:
  12:00 PM 9°C | 03:00 PM 11°C | 06:00 PM 8°C | 09:00 PM 7°C
```

### Location Search

```
$ weather-dashboard search "New York"

═══════════════════════════════════════════════════════════
  🔍 Search Results for "New York"
═══════════════════════════════════════════════════════════

  1. New York, US
     📍 Coordinates: 40.7128, -74.0060

  2. New York, US (Old)
     📍 Coordinates: 40.7142, -74.0064

Use weather-dashboard current "Location Name" to get weather
```

## API Integration

This tool uses the [OpenWeatherMap API](https://openweathermap.org/api):

- **Current Weather**: `GET /data/2.5/weather`
- **5-Day Forecast**: `GET /data/2.5/forecast`
- **Geocoding**: `GET /geo/1.0/direct`

### API Rate Limits (Free Tier)

- 60 calls/minute
- 1,000 calls/day
- 5-day forecast included

For higher limits, consider upgrading to a paid plan.

## Development

### Project Structure

```
weather-dashboard-cli/
├── bin/
│   └── weather-dashboard.js       # CLI entry point
├── src/
│   ├── cli.js                     # Commander.js CLI interface
│   ├── config/
│   │   └── index.js               # Configuration management
│   ├── services/
│   │   └── weather.js             # Weather API service
│   └── utils/
│       └── display.js             # Display formatting utilities
├── tests/
│   ├── config.test.js             # Configuration tests
│   └── weather.test.js            # Weather service tests
├── package.json                   # NPM package configuration
└── README.md                      # Documentation
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm test -- --coverage
```

### Linting

```bash
# Run ESLint
npm run lint

# Auto-fix issues
npm run lint -- --fix
```

## Troubleshooting

### API Key Issues

**Error**: `Invalid API key`

**Solution**:

1. Verify your API key at [OpenWeatherMap](https://home.openweathermap.org/api_keys)
2. Wait 10-15 minutes after creating a new key
3. Reconfigure with: `weather-dashboard config --api-key YOUR_KEY`

### Location Not Found

**Error**: `Location not found`

**Solution**:

1. Try including the country code: `"City, Country Code"`
2. Use the search command: `weather-dashboard search "City Name"`
3. Try alternative spellings or common names

### Rate Limiting

**Error**: `API rate limit exceeded`

**Solution**:

1. Wait a moment before trying again
2. Reduce the number of API calls
3. Consider upgrading to a paid plan for higher limits

### Network Errors

**Error**: `Network error`

**Solution**:

1. Check your internet connection
2. Verify firewall settings
3. Try again later

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenWeatherMap](https://openweathermap.org/) for providing the weather data API
- [Commander.js](https://github.com/tj/commander.js/) for the CLI framework
- [Chalk](https://github.com/chalk/chalk) for terminal colors
- [Figlet](http://www.figlet.org/) for ASCII art

---

**Made with ❤️ by RalphLoop Autonomous Development System**

_Date: January 21, 2026_
