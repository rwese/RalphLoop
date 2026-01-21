#!/usr/bin/env node

/**
 * RalphLoop CLI - Run the autonomous development system via container
 *
 * Usage:
 *   npx ralphloop [command] [options] [iterations]
 *   npx ralphloop --help
 *
 * Commands:
 *   run          Run the autonomous development loop (default)
 *   doctor       Check system requirements and diagnose issues
 *   examples     List available example projects
 *   quick        Quick-start with a built-in example
 *
 * Examples:
 *   npx ralphloop                   # Run with default 1 iteration
 *   npx ralphloop 10                # Run 10 iterations
 *   npx ralphloop doctor            # Diagnose system requirements
 *   npx ralphloop examples          # List available examples
 *   npx ralphloop quick todo        # Quick-start with todo-app example
 */

import { spawn, spawnSync } from 'child_process';
import { existsSync, readFileSync, promises as fs } from 'fs';
import { readFile } from 'fs/promises';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Configuration
const DEFAULT_BASE_IMAGE = 'ghcr.io/rwese/ralphloop';
const DEFAULT_IMAGE_TAG = 'latest';

// Build image with proper tag handling (support RALPH_IMAGE with or without tag)
function getDefaultImage() {
  const image = process.env.RALPH_IMAGE || DEFAULT_BASE_IMAGE;
  const tag = process.env.RALPH_IMAGE_TAG || DEFAULT_IMAGE_TAG;

  // If image already has a tag (contains :), don't add another
  if (image.includes(':')) {
    return image;
  }
  return `${image}:${tag}`;
}
const DEFAULT_IMAGE = getDefaultImage();
const DEFAULT_ITERATIONS = 1;
const EXAMPLES_DIR = join(__dirname, '..', 'examples');

/**
 * Load examples dynamically from the examples directory
 */
async function loadExamples() {
  const examples = [];

  try {
    const entries = await fs.readdir(EXAMPLES_DIR, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isDirectory()) {
        const promptPath = join(EXAMPLES_DIR, entry.name, 'prompt.md');

        if (existsSync(promptPath)) {
          // Try to read description from README.md or prompt.md
          let description = 'Example project';
          let iterations = '5-10';

          const readmePath = join(EXAMPLES_DIR, entry.name, 'README.md');
          if (existsSync(readmePath)) {
            try {
              const readmeContent = readFileSync(readmePath, 'utf8');
              const firstLine = readmeContent.split('\n')[0];
              if (firstLine && firstLine.length > 10) {
                description = firstLine.replace(/^#+\s*/, '').trim();
              }
            } catch {}
          }

          examples.push({
            name: entry.name,
            description: description,
            iterations: iterations,
            quick: entry.name.split('-')[0], // First word as quick alias
            prompt: `examples/${entry.name}/prompt.md`,
          });
        }
      }
    }
  } catch (error) {
    console.warn(`Warning: Could not load examples: ${error.message}`);
  }

  return examples;
}

/**
 * PromptBuilder command - Interactive prompt engineering tool
 */
async function promptBuilderCommand() {
  const idea = process.env.IDEA || '';

  console.log('\n📝 PromptBuilder - Interactive Prompt Engineering Tool\n');
  console.log('='.repeat(60));

  if (idea) {
    // Non-interactive mode with IDEA environment variable
    console.log(`\n💡 Processing your idea: "${idea}"\n`);
    console.log('Note: In non-interactive mode, PromptBuilder will generate a quality prompt.');
    console.log(
      'The implementing agent should ask clarifying questions and build a comprehensive prompt.\n'
    );
    console.log('='.repeat(60));
    console.log('\n📄 Generated Prompt:\n');
    console.log(`# Project Based on Your Idea: ${idea}\n`);
    console.log(`Build a solution that addresses: ${idea}`);
    console.log('\n## Core Features');
    console.log('- [ ] Define primary functionality');
    console.log('- [ ] Identify target users');
    console.log('- [ ] Establish key requirements');
    console.log('\n## Success Criteria');
    console.log('- [ ] Project is functional and complete');
    console.log('- [ ] All user needs are addressed');
    console.log('- [ ] Code is well-structured and tested');
    console.log('\n## Example Usage');
    console.log('- [ ] User can interact with the solution');
    console.log('- [ ] Features work as expected');
    console.log('\n## Bonus Features');
    console.log('- [ ] Additional nice-to-have features');
    console.log('\n' + '='.repeat(60));
    console.log(
      '\n💡 Tip: The implementing agent should ask clarifying questions to refine this prompt.\n'
    );
  } else {
    // Interactive mode
    console.log('\n💡 What is your idea you want to have built?');
    console.log('(This will be passed to RalphLoop for implementation)\n');
    console.log('='.repeat(60));
    console.log('\n✨ PromptBuilder generates a quality prompt that the implementing agent');
    console.log('will use to build your project.\n');
    console.log('The agent will ask clarifying questions to refine the prompt.');
    console.log('\nFor now, just describe your high-level idea:\n');
    console.log('Example: "Build a habit tracker for busy professionals"');
    console.log('Example: "Create a personal finance dashboard with charts"');
    console.log('Example: "Make a weather CLI tool with forecasts"\n');
    console.log('='.repeat(60));
    console.log('\n📝 Enter your idea (press Enter to continue with this description):\n');
  }

  return { shouldRun: true, iterations: 5 };
}

/**
 * Detect available container runtime (synchronous)
 */
function detectRuntimeSync(forceRuntime) {
  if (forceRuntime === 'podman' || forceRuntime === 'docker') {
    return { name: forceRuntime, available: true };
  }

  // Check for podman first (preferred on Linux/macOS)
  try {
    const result = spawnSync('which', ['podman']);
    if (result.status === 0 && result.stdout && result.stdout.toString().trim()) {
      return { name: 'podman', available: true };
    }
  } catch {}

  // Check for docker
  try {
    const result = spawnSync('which', ['docker']);
    if (result.status === 0 && result.stdout && result.stdout.toString().trim()) {
      return { name: 'docker', available: true };
    }
  } catch {}

  return { name: null, available: false };
}

/**
 * Spawn a process asynchronously with proper handling
 */
async function spawnAsync(command, args, options = {}) {
  const proc = spawn(command, args, {
    stdio: ['pipe', 'pipe', 'pipe'],
    ...options,
  });

  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      const text = data.toString();
      stdout += text;
      process.stdout.write(text);
    });

    proc.stderr.on('data', (data) => {
      const text = data.toString();
      stderr += text;
      process.stderr.write(text);
    });

    proc.on('close', (code) => {
      resolve({ code, stdout, stderr });
    });
  });
}

/**
 * Spawn sync with proper output capture
 */
function spawnCheckSync(command, args) {
  try {
    const result = spawnSync(command, args, { encoding: 'utf8' });
    return {
      success: result.status === 0,
      output: result.stdout?.trim() || '',
      error: result.stderr?.trim() || '',
    };
  } catch (error) {
    return { success: false, output: '', error: error.message };
  }
}

/**
 * Get the current working directory and git repo info
 */
function getProjectInfo() {
  const cwd = process.cwd();
  const isGitRepo = existsSync(join(cwd, '.git'));

  return { cwd, isGitRepo };
}

/**
 * Build the container run command
 */
function buildRunCommand(runtime, image, args, cwd, isGitRepo, command = null) {
  const commonArgs = [
    'run',
    '--rm',
    '-e',
    'HOME=/root',
    '-w',
    '/workspace',
    '-v',
    `${cwd}:/workspace`,
  ];

  // Add --userns=keep-id only for Podman (not supported by Docker)
  if (runtime === 'podman') {
    commonArgs.push('--userns=keep-id');
  }

  // Add git config if in a git repo (for commits)
  if (isGitRepo) {
    // Pass through git user config if available
    try {
      const userName = spawnSync('git', ['config', '--global', 'user.name']);
      const userEmail = spawnSync('git', ['config', '--global', 'user.email']);

      if (userName.status === 0 && userName.stdout && userName.stdout.toString().trim()) {
        commonArgs.push('-e', `GIT_USER_NAME=${userName.stdout.toString().trim()}`);
      }
      if (userEmail.status === 0 && userEmail.stdout && userEmail.stdout.toString().trim()) {
        commonArgs.push('-e', `GIT_USER_EMAIL=${userEmail.stdout.toString().trim()}`);
      }
    } catch {}
  }

  // Pass through GitHub token if available
  if (process.env.GITHUB_TOKEN) {
    commonArgs.push('-e', `GITHUB_TOKEN=${process.env.GITHUB_TOKEN}`);
  }

  // Pass through OpenCode auth if available
  if (process.env.OPENCODE_AUTH) {
    commonArgs.push('-e', `OPENCODE_AUTH=${process.env.OPENCODE_AUTH}`);
  }

  // Pass through RalphLoop prompt environment variables
  if (process.env.RALPH_PROMPT) {
    commonArgs.push('-e', `RALPH_PROMPT=${process.env.RALPH_PROMPT}`);
  }
  if (process.env.RALPH_PROMPT_FILE) {
    commonArgs.push('-e', `RALPH_PROMPT_FILE=${process.env.RALPH_PROMPT_FILE}`);
  }

  // Add image
  commonArgs.push(image);

  // Add command override (e.g., 'ralph') if specified
  if (command) {
    commonArgs.push(command);
  }

  // Add ralph arguments
  if (args.length > 0) {
    commonArgs.push(...args);
  }

  return [runtime, commonArgs];
}

/**
 * Display help message
 */
function showHelp() {
  const help = `
RalphLoop CLI - Autonomous Development System Runner

USAGE
  npx ralphloop [command] [options] [iterations]

COMMANDS
  run          Run the autonomous development loop (default command)
  doctor       Check system requirements and diagnose issues
  examples     List available example projects with descriptions
  quick        Quick-start with an example (auto-detected from examples/)
  prompt       Build a quality prompt from your idea
  help         Show this help message

ARGUMENTS
  iterations   Number of iterations to run (default: 1)

OPTIONS
  --runtime, -r            Container runtime: podman or docker (auto-detected)
  --image, -i              Docker image to use (default: ghcr.io/rwese/ralphloop:latest, can be overridden with RALPH_IMAGE/RALPH_IMAGE_TAG env vars)
  --pull                   Pull the latest image before running (default)
  --no-pull                Use cached image if available, pull only if missing
  --ralph-prompt-file, -p  Read prompt from file and pass to container
  --env                    Set environment variable (can be used multiple times)
  --help, -h               Show this help message
  --version, -V            Show version information

QUICK-START EXAMPLES
  # List all available examples
  npx ralphloop examples

  # Quick-start any example (auto-detected from examples/ directory)
  npx ralphloop quick todo
  npx ralphloop quick book
  npx ralphloop quick weather
  npx ralphloop quick finance
  npx ralphloop quick youtube

  # Build a prompt from your idea
  npx ralphloop prompt
  IDEA="Build a habit tracker" npx ralphloop prompt

CUSTOM PROMPT USAGE
  # Using --ralph-prompt-file (recommended - reads file directly)
  npx ralphloop --ralph-prompt-file ./examples/todo-app/prompt.md 10
  npx ralphloop -p ./my-prompt.md 5

  # Using --env flag
  npx ralphloop --env "RALPH_PROMPT=$(< ./examples/todo-app/prompt.md)" 10

  # Using environment variables (shell syntax)
  RALPH_PROMPT_FILE=./my-prompt.md npx ralphloop 5
  RALPH_PROMPT="Build a REST API" npx ralphloop 5

ENVIRONMENT VARIABLES
  GITHUB_TOKEN         GitHub token for API access (needed for private repos)
  OPENCODE_AUTH        OpenCode authentication data
  RALPH_PROMPT         Direct prompt text for the autonomous loop
  RALPH_PROMPT_FILE    Path to a prompt file
  RALPH_IMAGE          Container image name (e.g., 'localhost/ralphloop')
  RALPH_IMAGE_TAG      Image tag (e.g., 'v1-fix', 'latest')
                       Note: If RALPH_IMAGE contains a tag (e.g., 'image:tag'),
                       RALPH_IMAGE_TAG is ignored

CUSTOM IMAGE USAGE
  # Build and use local image (recommended for testing)
  podman build -t my-local-image:latest .
  RALPH_IMAGE=my-local-image npx ralphloop 1
  
  # Or with full image reference (RALPH_IMAGE_TAG will be ignored)
  RALPH_IMAGE=localhost/ralphloop:v1-fix npx ralphloop 1
  
  # Use --no-pull to skip updating existing images (still pulls if missing)
  RALPH_IMAGE=my-local-image npx ralphloop --no-pull 1
  
  # Use RALPH_IMAGE and RALPH_IMAGE_TAG separately
  RALPH_IMAGE=localhost/ralphloop RALPH_IMAGE_TAG=dev npx ralphloop 1

DIAGNOSIS
  Run "npx ralphloop doctor" to check your system setup and diagnose issues.

For more information, visit: https://github.com/rwese/RalphLoop
`;
  console.log(help);
}

/**
 * Show version
 */
async function showVersion() {
  try {
    const packageJson = await readFile(join(__dirname, '..', 'package.json'), 'utf-8');
    const { version } = JSON.parse(packageJson);
    console.log(`RalphLoop CLI v${version}`);
  } catch {
    console.log('RalphLoop CLI v1.0.0');
  }
}

/**
 * Pull the latest image
 */
async function pullImage(runtime, image) {
  console.log(`Pulling ${image}...`);
  const result = await spawnAsync(runtime, ['pull', image]);
  if (result.code !== 0) {
    console.error(`Failed to pull image: ${result.stderr}`);
    process.exit(1);
  }
  console.log('Image pulled successfully.');
}

/**
 * Check if image exists locally
 */
function imageExistsLocally(runtime, image) {
  const result = spawnCheckSync(runtime, ['images', '-q', image]);
  return result.success && result.output.length > 0;
}

/**
 * Doctor command - diagnose system requirements
 */
async function doctorCommand() {
  console.log('\n🩺 RalphLoop Doctor - System Diagnosis\n');
  console.log('='.repeat(50));

  const issues = [];
  const warnings = [];
  const checks = [];

  // 1. Node.js version
  console.log('\n📦 Node.js Environment');
  console.log('-'.repeat(30));
  const nodeVersion = process.version;
  const nodeMajor = parseInt(nodeVersion.slice(1).split('.')[0], 10);
  console.log(`  Node.js: ${nodeVersion}`);
  console.log(`  Platform: ${process.platform} (${process.arch})`);
  console.log(`  CWD: ${process.cwd()}`);
  if (nodeMajor >= 18) {
    console.log('  ✅ Node.js version OK (>= 18)');
    checks.push('Node.js version: OK');
  } else {
    console.log('  ⚠️  Node.js version may be old (< 18)');
    warnings.push('Node.js version is outdated');
  }

  // 2. Container runtime
  console.log('\n🐳 Container Runtime');
  console.log('-'.repeat(30));
  const podmanCheck = spawnCheckSync('which', ['podman']);
  const dockerCheck = spawnCheckSync('which', ['docker']);

  if (podmanCheck.success) {
    console.log('  ✅ Podman found');
    checks.push('Podman: Available');
  } else {
    console.log('  ❌ Podman not found');
  }

  if (dockerCheck.success) {
    console.log('  ✅ Docker found');
    checks.push('Docker: Available');
  } else {
    console.log('  ⚠️  Docker not found');
  }

  if (!podmanCheck.success && !dockerCheck.success) {
    issues.push('No container runtime (Podman or Docker) found');
    console.log('  ❌ ERROR: Please install Podman or Docker');
  } else {
    console.log('  ✅ At least one container runtime available');
  }

  // 3. Git configuration
  console.log('\n🔧 Git Configuration');
  console.log('-'.repeat(30));
  const gitName = spawnCheckSync('git', ['config', '--global', 'user.name']);
  const gitEmail = spawnCheckSync('git', ['config', '--global', 'user.email']);

  if (gitName.success && gitName.output) {
    console.log(`  ✅ Git user.name: ${gitName.output}`);
    checks.push('Git user.name: Set');
  } else {
    console.log('  ⚠️  Git user.name not configured');
    warnings.push('Git user.name not set (needed for commits)');
  }

  if (gitEmail.success && gitEmail.output) {
    console.log(`  ✅ Git user.email: ${gitEmail.output}`);
    checks.push('Git user.email: Set');
  } else {
    console.log('  ⚠️  Git user.email not configured');
    warnings.push('Git user.email not set (needed for commits)');
  }

  // 4. Environment variables
  console.log('\n🔑 Environment Variables');
  console.log('-'.repeat(30));
  const envVars = ['GITHUB_TOKEN', 'OPENCODE_AUTH'];
  for (const env of envVars) {
    const value = process.env[env];
    if (value && value.length > 0) {
      console.log(`  ✅ ${env}: Set (${value.length} chars)`);
      checks.push(`${env}: Set`);
    } else {
      console.log(`  ⚠️  ${env}: Not set (optional)`);
    }
  }

  // 5. Container image
  console.log('\n📦 Container Image');
  console.log('-'.repeat(30));
  const runtime = detectRuntimeSync(null);
  if (runtime.available) {
    const hasImage = imageExistsLocally(runtime.name, DEFAULT_IMAGE);
    if (hasImage) {
      console.log(`  ✅ Image cached: ${DEFAULT_IMAGE}`);
      checks.push('Container image: Cached');
    } else {
      console.log(`  ⚠️  Image not cached (will pull on first run)`);
      warnings.push('Container image not cached');
    }
  }

  // 6. Network connectivity test
  console.log('\n🌐 Network Connectivity');
  console.log('-'.repeat(30));
  try {
    const ghcrCheck = spawnCheckSync('curl', [
      '-s',
      '-o',
      '/dev/null',
      '-w',
      '%{http_code}',
      'https://ghcr.io',
    ]);
    if (ghcrCheck.success && ghcrCheck.output === '200') {
      console.log('  ✅ ghcr.io: Connected');
      checks.push('Network: ghcr.io accessible');
    } else {
      console.log(`  ⚠️  ghcr.io: HTTP ${ghcrCheck.output || 'unreachable'}`);
      warnings.push('Cannot reach ghcr.io (may need proxy/VPN)');
    }
  } catch {
    console.log('  ⚠️  Network test failed');
    warnings.push('Network connectivity test failed');
  }

  // 7. Current directory
  console.log('\n📁 Project Context');
  console.log('-'.repeat(30));
  const { cwd, isGitRepo } = getProjectInfo();
  console.log(`  Working directory: ${cwd}`);
  console.log(`  Git repository: ${isGitRepo ? 'Yes' : 'No'}`);

  if (!isGitRepo) {
    console.log('  ℹ️  Not in a git repository (some features may be limited)');
    warnings.push('Not in a git repository');
  } else {
    checks.push('Git repository: Detected');
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 DIAGNOSIS SUMMARY');
  console.log('='.repeat(50));
  console.log(`  ✅ Checks passed: ${checks.length}`);
  console.log(`  ⚠️  Warnings: ${warnings.length}`);
  console.log(`  ❌ Issues: ${issues.length}`);

  if (issues.length > 0) {
    console.log('\n❌ CRITICAL ISSUES (must fix):');
    for (const issue of issues) {
      console.log(`   - ${issue}`);
    }
  }

  if (warnings.length > 0) {
    console.log('\n⚠️  WARNINGS (recommended):');
    for (const warn of warnings) {
      console.log(`   - ${warn}`);
    }
  }

  if (checks.length > 0) {
    console.log('\n✅ PASSING CHECKS:');
    for (const check of checks) {
      console.log(`   ✓ ${check}`);
    }
  }

  console.log('\n📚 NEXT STEPS:');
  if (issues.length === 0) {
    console.log('   Your system looks ready! Try running:');
    console.log('   npx ralphloop examples    # See available examples');
    console.log('   npx ralphloop quick todo  # Quick-start with todo-app');
  } else {
    console.log('   Please fix the critical issues above, then try again.');
  }

  console.log('');
  return issues.length === 0;
}

/**
 * Examples command - list available examples (dynamically loaded)
 */
async function examplesCommand() {
  const examples = await loadExamples();

  console.log('\n📚 RalphLoop Example Projects\n');
  console.log('These are pre-built project templates you can start with:\n');
  console.log('='.repeat(60));

  for (const example of examples) {
    console.log(`\n📦 ${example.name}`);
    console.log(`   ${example.description}`);
    console.log(`   Estimated iterations: ${example.iterations}`);
    console.log(`   Quick start: npx ralphloop quick ${example.quick}`);
  }

  console.log('\n' + '='.repeat(60));
  console.log('\n🚀 HOW TO USE AN EXAMPLE');
  console.log('-'.repeat(60));
  console.log('\nOption 1: Quick start (easiest)');
  console.log('   npx ralphloop quick todo\n');

  console.log('Option 2: Using --ralph-prompt-file');
  console.log('   npx ralphloop -p examples/todo-app/prompt.md 10\n');

  console.log('Option 3: Using prompt-builder to craft your own');
  console.log('   npx ralphloop prompt\n');

  console.log('='.repeat(60));
  console.log('\n💡 TIP: Use "npx ralphloop quick <name>" to start any example.');
  console.log('   Run "npx ralphloop examples" to see all available examples.\n');
}

/**
 * Quick command - quick-start with an example (dynamically loaded)
 */
async function quickCommand(exampleName) {
  const examples = await loadExamples();

  // Build a lookup map from dynamically loaded examples
  const exampleMap = {};
  for (const example of examples) {
    // Add by quick alias (first word of name)
    exampleMap[example.quick.toLowerCase()] = example;
    // Also add by full name
    exampleMap[example.name.toLowerCase()] = example;
  }

  const example = exampleMap[exampleName.toLowerCase()];

  if (!example) {
    console.log(`\n❌ Unknown example: "${exampleName}"\n`);
    console.log('Available examples:');
    for (const ex of examples) {
      console.log(`  ${ex.quick.padEnd(10)} - ${ex.name}`);
    }
    console.log('\nUse "npx ralphloop examples" to see all examples.\n');
    return false;
  }

  console.log(`\n🚀 Quick-starting with: ${example.name}`);
  console.log(`   Prompt file: ${example.prompt}`);
  console.log(`   Iterations: ${example.iterations}\n`);

  // Set the environment variable and continue with run
  process.env.RALPH_PROMPT_FILE = example.prompt;
  return { shouldRun: true, iterations: parseInt(example.iterations.split('-')[0]) || 5 };
}

/**
 * Show usage guide when no prompt is configured
 */
function showUsageGuide() {
  const help = `
🤖 RalphLoop - Autonomous Development System

❌ No prompt configured!

To use RalphLoop, you need to provide a prompt that describes what to build.
Here are your options:

📦 OPTION 1: Use a built-in example (easiest)
   npx ralphloop quick todo       # Task management app
   npx ralphloop quick book       # Book collection manager
   npx ralphloop quick finance    # Finance dashboard
   npx ralphloop quick weather    # Weather CLI tool
   npx ralphloop quick youtube    # YouTube downloader

   Or list all examples:
   npx ralphloop examples

📄 OPTION 2: Use a local prompt file (recommended)
   npx ralphloop --ralph-prompt-file ./examples/todo-app/prompt.md 10
   npx ralphloop -p ./my-prompt.md 5

   # Or using environment variables:
   RALPH_PROMPT_FILE=./examples/todo-app/prompt.md npx ralphloop 10

📝 OPTION 3: Paste prompt directly
   # Using --env flag:
   npx ralphloop --env "RALPH_PROMPT=$(< ./examples/todo-app/prompt.md)" 10

   # Or using environment variables:
   RALPH_PROMPT="$(< ./examples/todo-app/prompt.md)" npx ralphloop 10

🔧 OPTION 4: Create your own prompt
   1. Create a prompt.md file describing your project
   2. Run: npx ralphloop --ralph-prompt-file ./prompt.md

💡 TIP: Run diagnostics first to check your setup:
   npx ralphloop doctor

📚 For more information:
   npx ralphloop --help
`;

  console.log(help);
}

/**
 * Main entry point
 */
async function main() {
  const args = process.argv.slice(2);

  // Check for no arguments
  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    showHelp();
    process.exit(0);
  }

  // Pre-parse options that need to be available before command detection
  let promptFileOverride = null;
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if ((arg === '--ralph-prompt-file' || arg === '-p') && args[i + 1]) {
      promptFileOverride = args[++i];
      break;
    }
  }

  // Load prompt file if specified
  if (promptFileOverride) {
    try {
      const content = readFileSync(promptFileOverride, 'utf-8');
      process.env.RALPH_PROMPT = content;
      console.log(`  ✓ Loaded prompt from ${promptFileOverride} (${content.length} chars)`);
    } catch (error) {
      console.error(`  ✗ Failed to read ${promptFileOverride}: ${error.message}`);
      process.exit(1);
    }
  }

  // Parse command - detect known commands first
  const knownCommands = ['run', 'doctor', 'examples', 'quick', 'prompt', 'help'];
  let command = 'run'; // default
  let commandArgs = args;

  // Find first non-option argument to determine command
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    // Skip --ralph-prompt-file when looking for commands
    if (arg === '--ralph-prompt-file' || arg === '-p') {
      i++; // skip the filename too
      continue;
    }
    if (!arg.startsWith('-') && knownCommands.includes(arg)) {
      command = arg;
      commandArgs = args.slice(i + 1);
      break;
    }
  }

  // Initialize variables early for command handlers
  let iterations = DEFAULT_ITERATIONS;
  const envOverrides = [];

  // Handle commands before options parsing
  if (command === 'doctor') {
    // For doctor, parse --env from the original args array
    for (let i = 0; i < args.length; i++) {
      const arg = args[i];
      if (arg === '--env' && args[i + 1]) {
        envOverrides.push(args[++i]);
      }
    }
    // Apply environment variable overrides for doctor output
    for (const envDef of envOverrides) {
      const [key, ...valueParts] = envDef.split('=');
      const value = valueParts.join('=');
      if (key && value !== undefined) {
        process.env[key] = value;
        console.log(`  ✓ Set ${key} from --env argument`);
      }
    }
    await doctorCommand();
    process.exit(0);
  }

  if (command === 'examples') {
    await examplesCommand();
    process.exit(0);
  }

  // PromptBuilder command - interactive prompt engineering tool
  if (command === 'prompt') {
    const result = await promptBuilderCommand();
    if (result && result.shouldRun) {
      // Continue to run the loop with the prompt-builder prompt
      process.env.RALPH_PROMPT_FILE = 'examples/prompt-builder/prompt.md';
      commandArgs[0] = (result.iterations || 5).toString();
    } else {
      process.exit(0);
    }
  }

  if (command === 'quick') {
    const exampleName = commandArgs[0];
    if (!exampleName) {
      console.log('\n❌ Please specify an example name\n');
      console.log('Usage: npx ralphloop quick [example]\n');
      console.log('Available examples:');
      const examples = await loadExamples();
      for (const ex of examples) {
        console.log(`  ${ex.quick.padEnd(10)} - ${ex.name}`);
      }
      console.log('\nRun "npx ralphloop examples" for all details.\n');
      process.exit(1);
    }
    const result = await quickCommand(exampleName);
    if (!result) {
      process.exit(1);
    }
    // Continue to run command with the result
    iterations = result.iterations;
  }

  if (command === 'help') {
    showHelp();
    process.exit(0);
  }

  // Parse options
  let runtime = null;
  let image = DEFAULT_IMAGE;
  let pullImageFlag = true; // Default to pulling latest image
  let extraArgs = [];

  for (let i = 0; i < commandArgs.length; i++) {
    const arg = commandArgs[i];

    if (arg === '--pull') {
      pullImageFlag = true;
      continue;
    }

    if (arg === '--no-pull') {
      pullImageFlag = false;
      continue;
    }

    if ((arg === '--runtime' || arg === '-r') && commandArgs[i + 1]) {
      runtime = commandArgs[++i];
      continue;
    }

    if ((arg === '--image' || arg === '-i') && commandArgs[i + 1]) {
      image = commandArgs[++i];
      continue;
    }

    if (arg === '--env' && commandArgs[i + 1]) {
      envOverrides.push(commandArgs[++i]);
      continue;
    }

    // Check if it's a number (iterations)
    if (/^\d+$/.test(arg)) {
      iterations = parseInt(arg, 10);
      continue;
    }

    // Pass through other arguments
    extraArgs.push(arg);
  }

  // Apply environment variable overrides
  for (const envDef of envOverrides) {
    const [key, ...valueParts] = envDef.split('=');
    const value = valueParts.join('=');
    if (key && value !== undefined) {
      process.env[key] = value;
      console.log(`  ✓ Set ${key} from --env argument`);
    }
  }

  // For commands that don't need a prompt, handle them before prompt check
  if (command === 'doctor') {
    // Doctor doesn't need a prompt - skip to detection
    // Detect runtime first to show in doctor output
  } else if (command === 'run') {
    // Check if prompt is configured for run command
    const hasPrompt = process.env.RALPH_PROMPT || process.env.RALPH_PROMPT_FILE;
    if (!hasPrompt) {
      showUsageGuide();
      process.exit(1);
    }
  }

  // Detect runtime
  const { name: detectedRuntime, available } = detectRuntimeSync(runtime);

  if (!available) {
    console.error('Error: No container runtime found.');
    console.error('Please install Podman (https://podman.io) or Docker (https://docker.com)');
    console.error('\nTip: Run "npx ralphloop doctor" to diagnose issues.\n');
    process.exit(1);
  }

  const finalRuntime = detectedRuntime;
  console.log(`Using container runtime: ${finalRuntime}`);

  // Get project info
  const { cwd, isGitRepo } = getProjectInfo();
  console.log(`Working directory: ${cwd}`);
  console.log(`Git repository: ${isGitRepo ? 'Yes' : 'No'}`);

  // Pull image if needed
  // Always pull if image doesn't exist locally (--no-pull only skips updating existing images)
  if (imageExistsLocally(finalRuntime, image)) {
    if (pullImageFlag) {
      console.log(`  ℹ️  Image cached: ${image} (use --no-pull to skip future pulls)`);
    } else {
      console.log(`  ✓ Using cached image: ${image}`);
    }
  } else {
    console.log(`  📦 Image not found locally, attempting to pull: ${image}`);
    await pullImage(finalRuntime, image);
  }

  // Build the run command
  const fullArgs = [iterations.toString(), ...extraArgs].filter((a) => a);
  const [runtimeCmd, containerArgs] = buildRunCommand(
    finalRuntime,
    image,
    fullArgs,
    cwd,
    isGitRepo,
    'ralph' // Execute ralph script inside container
  );

  console.log(`\nRunning: ${runtimeCmd} ${containerArgs.join(' ')}\n`);

  // Run the container
  const result = await spawnAsync(runtimeCmd, containerArgs, {
    cwd,
    env: { ...process.env },
  });

  process.exit(result.code);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
