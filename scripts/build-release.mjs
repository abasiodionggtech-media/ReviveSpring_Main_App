#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');
const releaseConfigPath = path.join(repoRoot, 'env', 'release.json');

if (!fs.existsSync(releaseConfigPath)) {
  console.error('Missing env/release.json. Copy env/release.example.json to env/release.json first.');
  process.exit(1);
}

const releaseConfig = JSON.parse(fs.readFileSync(releaseConfigPath, 'utf8'));
const dryRun = process.argv.includes('--dry-run');

const preferredJavaHome = '/usr/lib/jvm/java-17-openjdk-amd64';
const javaHome = fs.existsSync(path.join(preferredJavaHome, 'bin', 'java'))
  ? preferredJavaHome
  : (process.env.JAVA_HOME && fs.existsSync(path.join(process.env.JAVA_HOME, 'bin', 'java'))
    ? process.env.JAVA_HOME
    : preferredJavaHome);
const javaBin = path.join(javaHome, 'bin');
const env = {
  ...process.env,
  JAVA_HOME: javaHome,
  PATH: `${javaBin}${path.delimiter}${process.env.PATH || ''}`,
};

const dartDefines = Object.entries(releaseConfig).flatMap(([key, value]) => ['--dart-define', `${key}=${value}`]);
const args = ['build', 'apk', '--release', ...dartDefines];

if (dryRun) {
  console.log(`Would run: JAVA_HOME=${javaHome} PATH=${javaBin}:$PATH flutter ${args.join(' ')}`);
  process.exit(0);
}

console.log('Building release APK with env/release.json and Java 17...');
const result = spawnSync('flutter', args, {
  cwd: repoRoot,
  stdio: 'inherit',
  env,
  shell: false,
});

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);
