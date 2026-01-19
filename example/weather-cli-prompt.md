# WeatherPro - Professional CLI Weather Tool

Build a powerful, information-rich weather CLI tool that provides comprehensive weather data with beautiful visualizations. Designed for developers, sysadmins, and anyone who wants detailed weather info without leaving the terminal.

## Core Features

### Current Conditions

- **Current Weather**: Temperature, feels like, humidity, dew point, pressure
- **Wind**: Speed, direction, gusts, Beaufort scale description
- **Visibility**: Miles/km, air quality index (AQI) if available
- **Cloud Cover**: Oktas (0-8) with description
- **UV Index**: Current value with skin protection advice
- **Sun/Moon**: Sunrise, sunset, moon phase, moon illumination
- **Local Time**: Show local time for queried location

### Forecasts

- **Hourly Forecast**: Next 48 hours with temperature, precipitation, wind
- **Daily Forecast**: Next 7-14 days with highs/lows, precipitation chance
- **Min/Max Temps**: Daily range with historical comparison
- **Precipitation**: Hourly and daily precipitation amounts
- **Weather Icons**: ASCII art or emoji icons for each condition
- **Moon Phases**: Visual representation of moon for each day

### Alerts & Warnings

- **Weather Alerts**: Display active watches, warnings, advisories
- **Severity Levels**: Color-coded by severity (yellow, orange, red)
- **Alert Details**: Full alert text with timing and affected areas
- **Push Notifications**: Optional alerts via terminal bell or notify-send
- **Custom Alerts**: Set thresholds for personal alerts (e.g., "alert if temp > 100°F")

### Multiple Locations

- **Location Search**: Search by city name, ZIP code, coordinates, airport code
- **Saved Locations**: Save frequently checked locations
- **Location Aliases**: Create short names (e.g., "home", "office", "mom")
- **Auto-Detect**: Try to detect current location via IP or config
- **Distance Units**: Switch between mi/km for distance calculations

### Visualizations

- **Temperature Graph**: ASCII or unicode chart showing temp trend
- **Precipitation Chart**: Bar chart of expected rainfall
- **Wind Rose**: Simple wind direction visualization
- **Sun Path**: Daylight hours visualization
- **Color Output**: Use colors for temperature (blue-cellowarm-red scale)

## Technical Requirements

### Stack

- **Node.js v23.x** with npm
- **TypeScript** with strict mode
- **Ink** or **Blessed** for interactive TUI (optional)
- **Axios** for API calls
- **Figlet** for ASCII art headers
- **Weather API**: Open-Meteo (free, no key) or WeatherAPI (free tier available)

### CLI Interface

```bash
# Current conditions
weather                           # Current location
weather new york                  # By city name
weather 10001                     # By ZIP code
weather 40.7128,-74.0060          # By coordinates
weather JFK                       # By airport code

# Forecasts
weather -h                        # Hourly (default: 24h)
weather --hours 48                # 48 hour forecast
weather -d                        # Daily (default: 7 days)
weather --days 14                 # 14 day forecast
weather -a                        # All (hourly + daily)

# Specific information
weather -c                        # Current conditions only
weather -f                        # Forecast only
weather -A                        # Alerts only
weather -S                        # Sun/Moon times only

# Options
-u, --units metric|imperial       # Temperature units (default: auto)
-l, --location <name>             # Specify location
-s, --save <name>                 # Save as named location
-r, --refresh                     # Force refresh cache
-j, --json                        # JSON output (for scripting)
-q, --quiet                       # Minimal output
-v, --verbose                     # Extra details
-c, --color auto|always|never     # Color output (default: auto)

# Interactive mode
weather interactive               # Enter TUI mode
weather i                         # Shorthand
weather --watch                   # Auto-refresh every 5 minutes

# Location management
weather --list-locations          # Show saved locations
weather --delete-location <name>  # Delete saved location
weather --set-default <name>      # Set default location
weather --detect                  # Try to detect location

# Configuration
weather --config                  # Show config file
weather --set-units <system>      # Set default units
weather --set-api <provider>      # Change API provider
```

### API Integration

Default: Open-Meteo (free, no API key required)
Optional: WeatherAPI.com (free tier), OpenWeatherMap (free tier)

```javascript
// Config file ~/.config/weatherpro/config.json
{
  "defaultLocation": "home",
  "units": "imperial",
  "api": "open-meteo",
  "refreshInterval": 300,  // seconds
  "alertThreshold": {
    "tempMax": 100,
    "tempMin": 32,
    "windGust": 50,
    "precipitation": 1.0
  },
  "theme": {
    "color": true,
    "icons": "ascii",  // ascii, emoji, none
    "chartStyle": "block"  // block, bar, line
  }
}
```

### Caching & Performance

- **Cache Strategy**: Cache API responses, default 10 minutes
- **Offline Mode**: Show last known data if offline
- **Partial Data**: Show cached data while fetching new
- **Progress Indicators**: Show refresh status

### Error Handling

- **Network Errors**: Graceful degradation, show cached data
- **API Errors**: Helpful messages, try backup API
- **Invalid Location**: Search suggestions, nearby matches
- **Invalid Units**: Sanitize input, show available options

## Example Usage Scenarios

### Scenario 1: Quick Morning Check

```bash
$ weather
📍 New York, NY
🌡️ 72°F (68°F)  💧 45%  🌬️ 12mph NW

📈 Today: High 75°F, Low 62°F, 🌧️ 30%
🌙 Tonight: Low 62°F, Clear

☀️ Sunrise 6:22 AM  🌇 Sunset 7:45 PM
🌑 Moon: Waxing Crescent (18%)
```

### Scenario 2: Detailed Forecast

```bash
$ weather new york --days 7 --verbose

📍 New York, NY (40.7128, -74.0060)
Last updated: 2 min ago

CURRENT CONDITIONS
┌─────────────────────────────────────────┐
│ Temperature:     72°F (68°F)            │
│ Feels Like:      71°F                   │
│ Humidity:        45%                    │
│ Pressure:        30.12 inHg (stable)    │
│ Wind:            12mph NW (gusts 18mph) │
│ Visibility:      10 miles               │
│ UV Index:        6 (High)               │
└─────────────────────────────────────────┘

7-DAY FORECAST
Day           High/Low    Precip    Wind
─────────────────────────────────────────
Today         75/62°F     30%       12mph
Wed           78/65°F     40%       10mph
Thu           72/58°F     80%       8mph
Fri           68/55°F     20%       14mph
Sat           70/57°F     10%       10mph
Sun           75/60°F     15%       8mph
Mon           80/65°F     20%       6mph

HOURLY (Next 24h)
02PM 72°F 🌤️ 10%
03PM 73°F 🌤️ 5%
04PM 73°F ☀️ 0%
05PM 72°F ☀️ 0%
...
02AM 65°F 🌕 0%

ACTIVE ALERTS
⚠️ No active alerts for New York, NY
```

### Scenario 3: Travel Planning

```bash
$ weather tokyo -d --json | jq '.[] | select(.precipChance > 50) | .date'
"2024-10-15"  // Bring umbrella!

$ weather denver --verbose | grep -A2 "Wind"
Wind:            25mph NW (gusts 40mph)
⚠️  Wind advisory in effect. Use caution.
```

### Scenario 4: Scripting & Automation

```bash
#!/bin/bash
# Get weather and set desktop background based on conditions

WEATHER=$(weather --json)
TEMP=$(echo $WEATHER | jq '.current.temp')
CONDITION=$(echo $WEATHER | jq -r '.current.condition.code')

if [ $TEMP -gt 80 ]; then
    set-wallpaper sunny.jpg
elif [ $TEMP -lt 40 ]; then
    set-wallpaper snowy.jpg
else
    set-wallpaper mild.jpg
fi
```

### Scenario 5: Weather Watch

```bash
$ weather --watch
# Updates every 5 minutes with bell notification on changes
# Press Ctrl+C to exit
```

## Success Criteria

- [ ] **Fast**: Results in under 2 seconds
- [ ] **Beautiful**: Great use of colors, icons, and ASCII art
- [ ] **Informative**: Provides useful data, not just temperature
- [ ] **Scriptable**: JSON output works well for automation
- [ ] **Works Offline**: Shows cached data when offline
- [ ] **No API Key**: Works out of the box (Open-Meteo)
- [ ] **Interactive Mode**: TUI is intuitive and responsive
- [ ] **Helpful Errors**: Clear messages when things go wrong
- [ ] **Cross-Platform**: Works on macOS, Linux, WSL, Windows
- [ ] **Low Memory**: Minimal resource usage

## Bonus Features

- [ ] **Weather Maps**: ASCII radar maps for precipitation
- [ ] **Historical Data**: Compare to historical averages
- [ ] **Almanac**: Day's historical weather records
- [ ] **Clothing Recommendations**: "Wear a light jacket today"
- [ ] **Activity Suggestions**: Outdoor activities based on weather
- [ ] **Pollen Count**: Allergy information
- [ ] **Sun/Photo Windows**: Best times for photography
- [ ] **Travel Advisory**: Driving/flight conditions
- [ ] **Multiple Providers**: WeatherAPI, OpenWeatherMap options
- [ ] **Web Dashboard**: Simple local web server for browser access
- [ ] **Desktop Widget**: macOS Today widget or Linux desktop widget
- [ ] **Notification Center**: Desktop notifications for alerts
- [ ] **Smart Watch Integration**: Apple Watch / Wear OS companion
