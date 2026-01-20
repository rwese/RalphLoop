# Weather Dashboard CLI

A sophisticated command-line weather tool with beautiful terminal output, API integration, and comprehensive weather data.

## Features

- 🌤️ **Current Weather**: Get real-time weather conditions for any location
- 📈 **Weather Forecasts**: Multi-day forecasts with detailed information
- 🔍 **Location Search**: Find locations by name or coordinates
- ⚙️ **Configuration Management**: Persistent settings and API key management
- 🎨 **Beautiful Output**: Colorized terminal output with weather icons
- 🌍 **Multiple Units**: Support for metric, imperial, and kelvin units
- 🧪 **Well Tested**: Comprehensive unit test coverage
- 📦 **Easy Installation**: Simple npm installation and setup

## Installation

### Global Installation (Recommended)

```bash
npm install -g weather-dashboard-cli
```

### Local Installation

```bash
npm install weather-dashboard-cli
```

## Quick Start

1. **Get an OpenWeatherMap API Key**
   - Sign up at [OpenWeatherMap](https://openweathermap.org/api)
   - Get your free API key

2. **Configure the CLI**

   ```bash
   # Set your API key
   weather config --set apiKey=your_api_key_here

   # Or set environment variable
   export OPENWEATHER_API_KEY=your_api_key_here
   ```

3. **Get weather data**

   ```bash
   # Current weather
   weather current London

   # Weather forecast
   weather forecast "New York" --days 5

   # Search for locations
   weather search Paris
   ```

## Usage

### Commands

#### `weather current <location>`

Get current weather conditions for a location.

```bash
weather current London
weather current "New York,US"
weather current 51.5074,-0.1278
weather current Tokyo --units imperial
```

**Options:**

- `-u, --units <units>`: Temperature units (`metric`, `imperial`, `kelvin`)

#### `weather forecast <location>`

Get weather forecast for 1-5 days.

```bash
weather forecast London
weather forecast Paris --days 5
weather forecast Berlin --units metric --days 3
```

**Options:**

- `-d, --days <days>`: Number of days (1-5, default: 3)
- `-u, --units <units>`: Temperature units (`metric`, `imperial`, `kelvin`)

#### `weather search <query>`

Search for locations by name.

```bash
weather search London
weather search "New York"
weather search Paris
```

#### `weather config`

Manage configuration settings.

```bash
# Show current configuration
weather config

# Set API key
weather config --set apiKey=your_api_key

# Set preferred units
weather config --set units=imperial
```

**Configuration Options:**

- `apiKey`: OpenWeatherMap API key
- `units`: Preferred temperature units (`metric`, `imperial`, `kelvin`)

### Location Formats

You can specify locations in several ways:

1. **City Name**: `London`, `Paris`, `Tokyo`
2. **City, Country**: `London,GB`, `Paris,FR`, `New York,US`
3. **Coordinates**: `51.5074,-0.1278` (latitude,longitude)
4. **City, State, Country**: `New York,NY,US`

### Examples

```bash
# Basic usage
weather current London
weather forecast "New York" --days 5

# With different units
weather current Tokyo --units imperial
weather forecast Berlin --units kelvin

# Using coordinates
weather current 51.5074,-0.1278

# Search for locations
weather search Paris

# Configuration
weather config --set apiKey=your_key_here
weather config --set units=metric
```

## Output Examples

### Current Weather

```
📍 London, GB
──────────────────────────────────────────────────
☀️ 15°C
Feels like: 12°C
Clear sky

📊 Details:
  💧 Humidity: 65%
  🌡️  Pressure: 1013 hPa
  💨 Wind: 3.5 m/s SW

🌅 Sunrise: 6:45:30 AM
🌇 Sunset: 5:23:45 PM
```

### Weather Forecast

```
📍 London, GB - Forecast
──────────────────────────────────────────────────

Mon ☀️
Clear sky
12°C / 18°C
💧 60%  💨 3.2 m/s

Tue ⛅
Few clouds
10°C / 16°C
💧 70%  💨 4.1 m/s
```

## Configuration

### Environment Variables

You can use environment variables for configuration:

```bash
export OPENWEATHER_API_KEY=your_api_key_here
export DEFAULT_UNITS=metric
export DEFAULT_LANGUAGE=en
```

### Configuration File

The CLI stores configuration in `~/.weather-cli.json`:

```json
{
  "apiKey": "your_api_key_here",
  "units": "metric"
}
```

## API Integration

### OpenWeatherMap API

This CLI uses the OpenWeatherMap API for weather data:

- **Current Weather**: `/weather` endpoint
- **5-Day Forecast**: `/forecast` endpoint
- **Geocoding**: `/geo/1.0/direct` endpoint
- **Reverse Geocoding**: `/geo/1.0/reverse` endpoint

### Rate Limits

- **Free Plan**: 1,000 calls/day, 60 calls/minute
- **Weather Data**: Updated every 10 minutes
- **Forecast Data**: 5-day forecast with 3-hour intervals

## Development

### Prerequisites

- Node.js 16.0.0 or higher
- npm 7.0.0 or higher

### Setup

```bash
# Clone the repository
git clone https://github.com/your-repo/weather-dashboard-cli.git
cd weather-dashboard-cli

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your API key

# Run tests
npm test

# Run CLI in development
npm start current London
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm run test:coverage
```

### Project Structure

```
weather-cli/
├── bin/
│   └── weather.js          # CLI entry point
├── src/
│   ├── weather-service.js  # API integration service
│   └── formatter.js       # Terminal output formatting
├── test/
│   └── weather-service.test.js  # Unit tests
├── package.json           # npm package configuration
├── README.md             # This file
├── .env.example          # Environment template
└── .env                  # Environment configuration
```

## Testing

The project includes comprehensive unit tests covering:

- Configuration management
- API validation
- Location parsing
- Data processing
- Error handling
- Output formatting

Run tests with:

```bash
npm test
```

## Troubleshooting

### Common Issues

1. **"API key not configured"**
   - Set your OpenWeatherMap API key using `weather config --set apiKey=your_key`
   - Or set the `OPENWEATHER_API_KEY` environment variable

2. **"Location not found"**
   - Check spelling of the location name
   - Try using "City,Country" format (e.g., "Paris,FR")
   - Use coordinates format: "lat,lon"

3. **"Network error"**
   - Check your internet connection
   - Verify the OpenWeatherMap service is available
   - Check if you've exceeded API rate limits

4. **Colors not displaying**
   - Colors are automatically disabled when output is piped
   - Ensure your terminal supports ANSI color codes

### Debug Mode

Set the `DEBUG` environment variable for detailed logging:

```bash
DEBUG=weather* weather current London
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow existing code style and patterns
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://github.com/your-repo/weather-dashboard-cli#readme)
- 🐛 [Bug Reports](https://github.com/your-repo/weather-dashboard-cli/issues)
- 💬 [Discussions](https://github.com/your-repo/weather-dashboard-cli/discussions)

## Acknowledgments

- [OpenWeatherMap](https://openweathermap.org/) for weather data API
- [Commander.js](https://github.com/tj/commander.js) for CLI framework
- [Chalk](https://github.com/chalk/chalk) for terminal styling
- [Axios](https://github.com/axios/axios) for HTTP requests
