# WeatherPro - Professional CLI Weather Tool

A powerful, information-rich weather CLI tool that provides comprehensive weather data with beautiful visualizations.

## Overview

Build a terminal-based weather tool with:

- Current conditions and forecasts
- Weather alerts and warnings
- Multiple location support
- Beautiful ASCII visualizations

## Running with RalphLoop

```bash
# Run with 5 iterations (path is relative to /workspace inside container)
RALPH_PROMPT_FILE=/workspace/examples/weather-cli/prompt.md npm run container:run 5

# Or set RALPH_PROMPT directly from the file
RALPH_PROMPT="$(cat examples/weather-cli/prompt.md)" npm run container:run 5
```

> **Note:** `RALPH_PROMPT_FILE` paths are relative to `/workspace` inside the container.

## Key Features

### Current Conditions

- Temperature, feels like, humidity, pressure
- Wind speed, direction, and gusts
- UV index and sun/moon times

### Forecasts

- 48-hour hourly forecasts
- 7-14 day daily forecasts
- Precipitation chances and amounts
- ASCII weather icons

### Alerts

- Active watches and warnings
- Color-coded severity levels
- Full alert details

## Files

- `prompt.md` - Complete project specification for RalphLoop
