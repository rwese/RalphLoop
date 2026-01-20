#!/usr/bin/env node

/**
 * RalphLoop CLI - Run the autonomous development system via container
 *
 * Usage:
 *   npx ralphloop [--podman | --docker] [iterations]
 *   npx ralphloop --help
 *
 * Examples:
 *   npx ralphloop                    # Run with default 1 iteration
 *   npx ralphloop 10                 # Run 10 iterations
 *   npx ralphloop --podman 5         # Force podman, run 5 iterations
 *   npx ralphloop --image ghcr.io/rwese/ralphloop:latest
 */

import { spawn, spawnSync } from 'child_process';
import { existsSync } from 'fs';
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
    '-it',
    '--userns=keep-id',
    '-e',
    'HOME=/root',
    '-w',
    '/workspace',
    '-v',
    `${cwd}:/workspace`,
  ];

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
  npx ralphloop [options] [iterations]

ARGUMENTS
  iterations    Number of iterations to run (default: 1)

OPTIONS
  --runtime, -r    Container runtime: podman or docker (auto-detected)
  --image, -i      Docker image to use (default: ${DEFAULT_IMAGE})
  --help, -h       Show this help message
  --version, -V    Show version information
  --pull           Always pull the latest image before running
  --no-pull        Skip pulling the image

EXAMPLES
  # Run with default settings (1 iteration)
  npx ralphloop
  
  # Run 10 iterations
  npx ralphloop 10
  
  # Force Docker (instead of auto-detected Podman)
  npx ralphloop --docker 5
  
  # Use a specific image tag
  npx ralphloop --image ghcr.io/rwese/ralphloop:v1.0.0
  
  # Run with environment variables
  npx ralphloop 3

ENVIRONMENT VARIABLES
  GITHUB_TOKEN       GitHub token for API access (needed for private repos)
  CONTEXT7_API_KEY   Context7 documentation lookup key
  OPENCODE_AUTH      OpenCode authentication data

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
 * Main entry point
 */
async function main() {
  const args = process.argv.slice(2);

  // Parse options
  let runtime = null;
  let image = DEFAULT_IMAGE;
  let iterations = DEFAULT_ITERATIONS;
  let pullImageFlag = false;
  let extraArgs = [];

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === '--help' || arg === '-h') {
      showHelp();
      process.exit(0);
    }

    if (arg === '--version' || arg === '-V') {
      await showVersion();
      process.exit(0);
    }

    if (arg === '--pull') {
      pullImageFlag = true;
      continue;
    }

    if (arg === '--no-pull') {
      pullImageFlag = false;
      continue;
    }

    if ((arg === '--runtime' || arg === '-r') && args[i + 1]) {
      runtime = args[++i];
      continue;
    }

    if ((arg === '--image' || arg === '-i') && args[i + 1]) {
      image = args[++i];
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

  // Detect runtime
  const { name: detectedRuntime, available } = detectRuntimeSync(runtime);

  if (!available) {
    console.error('Error: No container runtime found.');
    console.error('Please install Podman (https://podman.io) or Docker (https://docker.com)');
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
    env: { ...process.env, TERM: process.env.TERM || 'xterm' },
  });

  process.exit(result.code);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
