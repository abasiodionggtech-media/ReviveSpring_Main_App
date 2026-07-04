import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, rmSync, cpSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');
const appDir = path.join(rootDir, 'revivespring-react');
const appBuildDir = path.join(appDir, 'build');
const hostingerBuildDir = path.join(rootDir, 'build');
const npmCommand = process.platform === 'win32' ? 'npm.cmd' : 'npm';

function run(command, args, cwd) {
  const result = spawnSync(command, args, {
    cwd,
    stdio: 'inherit',
    shell: false,
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

run(npmCommand, ['install'], appDir);
run(npmCommand, ['run', 'build'], appDir);

if (!existsSync(appBuildDir)) {
  console.error(`React build output was not found at ${appBuildDir}`);
  process.exit(1);
}

mkdirSync(hostingerBuildDir, { recursive: true });

for (const entry of ['index.html', '.htaccess', 'assets']) {
  const target = path.join(hostingerBuildDir, entry);
  if (existsSync(target)) {
    rmSync(target, { recursive: true, force: true });
  }
}

for (const entry of readdirSync(appBuildDir)) {
  cpSync(path.join(appBuildDir, entry), path.join(hostingerBuildDir, entry), {
    recursive: true,
  });
}

console.log(`Hostinger output prepared at ${hostingerBuildDir}`);
