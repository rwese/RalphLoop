#!/usr/bin/env node

/**
 * bin/json-query.cjs - JSON Query Utility for RalphLoop
 *
 * Purpose:
 *   Provides command-line JSON file querying and modification capabilities
 *   for RalphLoop configuration management. Supports nested key access,
 *   value retrieval, and value modification.
 *
 * Key Features:
 *   - Get nested values from JSON files using dot notation
 *   - Set nested values with automatic type parsing (boolean, number, string)
 *   - Array index support (e.g., backends[0].name)
 *   - Automatic backup before modifications
 *   - Pretty-printed output for complex values
 *
 * Usage:
 *   node json-query.cjs <json-file> <key> [--get|--set <value>]
 *
 * Arguments:
 *   <json-file>     Path to JSON configuration file
 *   <key>           Dot-notation key path (e.g., "backends.opencode.enabled")
 *   [--get]         Retrieve value (default)
 *   [--set <value>] Set value with automatic type detection
 *
 * Examples:
 *   # Get a value
 *   node json-query.cjs config.json backends.opencode.enabled --get
 *
 *   # Set a boolean
 *   node json-query.cjs config.json backends.mock.enabled --set true
 *
 *   # Set a number
 *   node json-query.cjs config.json settings.timeout --set 300
 *
 *   # Set a string (use quotes)
 *   node json-query.cjs config.json info.name --set "My App"
 *
 * Key Path Syntax:
 *   - Simple keys: "backends"
 *   - Nested keys: "backends.opencode"
 *   - Array access: "backends[0].name"
 *   - Combined: "backends[0].config.settings.timeout"
 *
 * Type Detection:
 *   - "true"/"false" → boolean
 *   - Integer strings → number
 *   - Float strings → number
 *   - Quoted strings → string (quotes removed)
 *   - Other strings → string
 *
 * Related Files:
 *   - backends/index.jsonc: Configuration file queried by this tool
 *   - bin/ralph-config: Higher-level configuration management wrapper
 */

const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const filePath = args[0];
const key = args[1];
const action = args[2];
const value = args[3];

// Get nested value from object
function getNestedValue(obj, keyPath) {
  const keys = keyPath.split('.');
  let result = obj;

  for (const key of keys) {
    if (result === undefined || result === null) {
      return undefined;
    }

    // Handle array indices
    if (key.includes('[')) {
      const match = key.match(/^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+)\]$/);
      if (match) {
        result = result[match[1]];
        const index = parseInt(match[2], 10);
        if (Array.isArray(result)) {
          result = result[index];
        } else {
          return undefined;
        }
      } else {
        return undefined;
      }
    } else {
      result = result[key];
    }
  }

  return result;
}

// Set nested value in object
function setNestedValue(obj, keyPath, newValue) {
  const keys = keyPath.split('.');
  let current = obj;

  for (let i = 0; i < keys.length - 1; i++) {
    const key = keys[i];

    // Handle array indices
    if (key.includes('[')) {
      const match = key.match(/^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+)\]$/);
      if (match) {
        const arrName = match[1];
        const index = parseInt(match[2], 10);

        if (!current[arrName]) {
          current[arrName] = [];
        }
        if (!Array.isArray(current[arrName])) {
          current[arrName] = [];
        }

        // Create intermediate objects/arrays if needed
        for (let j = current[arrName].length; j <= index; j++) {
          current[arrName][j] = (j === index) ? {} : [];
        }

        current = current[arrName][index];
      } else {
        return false;
      }
    } else {
      if (!current[key] || typeof current[key] !== 'object') {
        current[key] = {};
      }
      current = current[key];
    }
  }

  // Set the final value
  const lastKey = keys[keys.length - 1];
  let parsedValue = newValue;

  // Parse value based on type
  if (newValue === 'true') {
    parsedValue = true;
  } else if (newValue === 'false') {
    parsedValue = false;
  } else if (/^-?\d+$/.test(newValue)) {
    parsedValue = parseInt(newValue, 10);
  } else if (/^-?\d+\.\d+$/.test(newValue)) {
    parsedValue = parseFloat(newValue);
  } else if (newValue.startsWith('"') && newValue.endsWith('"')) {
    parsedValue = newValue.slice(1, -1);
  }

  current[lastKey] = parsedValue;
  return true;
}

// Main function
function main() {
  if (!filePath || !key) {
    console.error('Usage: json-query.js <json-file> <key> [--get|--set <value>]');
    process.exit(1);
  }

  if (!fs.existsSync(filePath)) {
    console.error(`Error: File not found: ${filePath}`);
    process.exit(1);
  }

  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(content);

    if (action === '--get' || !action) {
      // Get value
      const result = getNestedValue(data, key);
      if (result !== undefined) {
        // Handle different types
        if (typeof result === 'object') {
          console.log(JSON.stringify(result, null, 2));
        } else {
          console.log(result);
        }
      } else {
        console.error(`Key not found: ${key}`);
        process.exit(1);
      }
    } else if (action === '--set') {
      if (!value) {
        console.error('Error: --set requires a value');
        process.exit(1);
      }

      // Backup original file
      fs.writeFileSync(`${filePath}.bak`, content);

      if (setNestedValue(data, key, value)) {
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n');
        console.log(`✅ Set ${key} = ${value}`);
      } else {
        console.error(`Failed to set value: ${key}`);
        fs.unlinkSync(`${filePath}.bak`);
        process.exit(1);
      }

      // Clean up backup
      if (fs.existsSync(`${filePath}.bak`)) {
        fs.unlinkSync(`${filePath}.bak`);
      }
    } else {
      console.error(`Unknown action: ${action}`);
      process.exit(1);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
