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
import { existsSync, readFileSync } from 'fs';
import { readFile } from 'fs/promises';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Configuration
const DEFAULT_IMAGE = 'ghcr.io/rwese/ralphloop:latest';
const DEFAULT_ITERATIONS = 1;

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
      error: result.stderr?.trim() || ''
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

  // Pass through Context7 API key if available
  if (process.env.CONTEXT7_API_KEY) {
    commonArgs.push('-e', `CONTEXT7_API_KEY=${process.env.CONTEXT7_API_KEY}`);
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
  quick        Quick-start with a built-in example (see usage below)
  help         Show this help message

ARGUMENTS
  iterations   Number of iterations to run (default: 1)

OPTIONS
  --runtime, -r      Container runtime: podman or docker (auto-detected)
  --image, -i        Docker image to use (default: ${DEFAULT_IMAGE})
  --pull             Pull the latest image before running (default)
  --no-pull          Skip pulling the image, use cached version
  --help, -h         Show this help message
  --version, -V      Show version information

QUICK-START EXAMPLES
  # Run the todo-app example (10 iterations)
  npx ralphloop quick todo

  # Run the book-collection example (15 iterations)
  npx ralphloop quick book

  # Run the weather-cli example (5 iterations)
  npx ralphloop quick weather

  # Run the finance-dashboard example (15 iterations)
  npx ralphloop quick finance

  # Run the youtube-cli example (10 iterations)
  npx ralphloop quick youtube

CUSTOM PROMPT USAGE
  # Using a local prompt file
  RALPH_PROMPT_FILE=./my-prompt.md npx ralphloop 5

  # Using prompt from file (relative to project root)
  RALPH_PROMPT="$(< ./examples/todo-app/prompt.md)" npx ralphloop 10

  # Using direct prompt
  RALPH_PROMPT="Build a REST API for user management" npx ralphloop 5

ENVIRONMENT VARIABLES
  GITHUB_TOKEN         GitHub token for API access (needed for private repos)
  CONTEXT7_API_KEY     Context7 documentation lookup key
  OPENCODE_AUTH        OpenCode authentication data
  RALPH_PROMPT         Direct prompt text for the autonomous loop
  RALPH_PROMPT_FILE    Path to a prompt file

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
  const envVars = ['GITHUB_TOKEN', 'CONTEXT7_API_KEY', 'OPENCODE_AUTH'];
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
    const ghcrCheck = spawnCheckSync('curl', ['-s', '-o', '/dev/null', '-w', '%{http_code}', 'https://ghcr.io']);
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
 * Examples command - list available examples
 */
async function examplesCommand() {
  console.log('\n📚 RalphLoop Example Projects\n');
  console.log('These are pre-built project templates you can start with:\n');
  console.log('='.repeat(60));

  const examples = [
    {
      name: 'todo-app',
      iterations: '10-15',
      description: 'Modern task management web app with PWA support',
      quick: 'todo'
    },
    {
      name: 'book-collection',
      iterations: '15-20',
      description: 'Personal library management system',
      quick: 'book'
    },
    {
      name: 'finance-dashboard',
      iterations: '15-20',
      description: 'Personal finance tracking and budgeting',
      quick: 'finance'
    },
    {
      name: 'weather-cli',
      iterations: '5-10',
      description: 'Professional CLI weather tool',
      quick: 'weather'
    },
    {
      name: 'youtube-cli',
      iterations: '10-15',
      description: 'YouTube download and media management',
      quick: 'youtube'
    }
  ];

  examples.forEach((example) => {
    console.log(`\n📦 ${example.name}`);
    console.log(`   ${example.description}`);
    console.log(`   Estimated iterations: ${example.iterations}`);
    console.log(`   Quick start: npx ralphloop quick ${example.quick}`);
  });

  console.log('\n' + '='.repeat(60));
  console.log('\n🚀 HOW TO USE AN EXAMPLE');
  console.log('-'.repeat(60));
  console.log('\nOption 1: Quick start (easiest)');
  console.log('   npx ralphloop quick todo\n');

  console.log('Option 2: Using pre-installed examples (in container)');
  console.log('   RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md \\\\\n   npx ralphloop 10\n');

  console.log('Option 3: Using local prompt file');
  console.log('   RALPH_PROMPT_FILE=./examples/todo-app/prompt.md npx ralphloop 10\n');

  console.log('Option 4: Paste prompt directly');
  console.log('   RALPH_PROMPT="$(< ./examples/todo-app/prompt.md)" npx ralphloop 10\n');

  console.log('');
}

/**
 * Quick command - quick-start with an example
 */
async function quickCommand(exampleName) {
  const examples = {
    todo: { name: 'todo-app', prompt: 'examples/todo-app/prompt.md', iterations: 10 },
    book: { name: 'book-collection', prompt: 'examples/book-collection/prompt.md', iterations: 15 },
    finance: { name: 'finance-dashboard', prompt: 'examples/finance-dashboard/prompt.md', iterations: 15 },
    weather: { name: 'weather-cli', prompt: 'examples/weather-cli/prompt.md', iterations: 5 },
    youtube: { name: 'youtube-cli', prompt: 'examples/youtube-cli/prompt.md', iterations: 10 }
  };

  const example = examples[exampleName.toLowerCase()];

  if (!example) {
    console.log(`\n❌ Unknown example: "${exampleName}"\n`);
    console.log('Available examples:');
    Object.keys(examples).forEach((key) => {
      console.log(`  ${key.padEnd(10)} - ${examples[key].name}`);
    });
    console.log('\nUse "npx ralphloop examples" to see details.\n');
    return false;
  }

  console.log(`\n🚀 Quick-starting with: ${example.name}`);
  console.log(`   Prompt file: ${example.prompt}`);
  console.log(`   Iterations: ${example.iterations}\n`);

  // Set the environment variable and continue with run
  process.env.RALPH_PROMPT_FILE = example.prompt;
  return { shouldRun: true, iterations: example.iterations };
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

📄 OPTION 2: Use a local prompt file
   # From project root with examples:
   RALPH_PROMPT_FILE=./examples/todo-app/prompt.md npx ralphloop 10

   # From anywhere:
   RALPH_PROMPT_FILE=/path/to/my-prompt.md npx ralphloop 5

📝 OPTION 3: Paste prompt directly
   # Using command substitution:
   RALPH_PROMPT="$(< ./examples/todo-app/prompt.md)" npx ralphloop 10

   # Or set directly (for short prompts):
   RALPH_PROMPT="Build a REST API for user authentication" npx ralphloop 5

🔧 OPTION 4: Create your own prompt
   1. Create a prompt.md file describing your project
   2. Run: RALPH_PROMPT_FILE=./prompt.md npx ralphloop

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

  // Parse command
  const command = args[0].startsWith('-') ? 'run' : args[0];
  const commandArgs = command === 'run' ? args : args.slice(1);

  // Handle commands
  if (command === 'doctor') {
    await doctorCommand();
    process.exit(0);
  }

  if (command === 'examples') {
    await examplesCommand();
    process.exit(0);
  }

  if (command === 'quick') {
    const exampleName = commandArgs[0];
    if (!exampleName) {
      console.log('\n❌ Please specify an example name\n');
      console.log('Usage: npx ralphloop quick [example]\n');
      console.log('Available examples:');
      console.log('  todo     - Task management web app');
      console.log('  book     - Book collection manager');
      console.log('  finance  - Personal finance dashboard');
      console.log('  weather  - Weather CLI tool');
      console.log('  youtube  - YouTube downloader');
      console.log('\nRun "npx ralphloop examples" for details.\n');
      process.exit(1);
    }
    const result = await quickCommand(exampleName);
    if (!result) {
      process.exit(1);
    }
    // Continue with run command using result.iterations
    commandArgs[0] = result.iterations.toString();
  }

  if (command === 'help') {
    showHelp();
    process.exit(0);
  }

  // Parse options
  let runtime = null;
  let image = DEFAULT_IMAGE;
  let iterations = DEFAULT_ITERATIONS;
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

    // Check if it's a number (iterations)
    if (/^\d+$/.test(arg)) {
      iterations = parseInt(arg, 10);
      continue;
    }

    // Pass through other arguments
    extraArgs.push(arg);
  }

  // Check if prompt is configured
  const hasPrompt = process.env.RALPH_PROMPT || process.env.RALPH_PROMPT_FILE;
  if (!hasPrompt && command === 'run') {
    showUsageGuide();
    process.exit(1);
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

  // Pull image if requested
  if (pullImageFlag) {
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
