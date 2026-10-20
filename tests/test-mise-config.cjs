const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const repo = path.resolve(__dirname, '..');
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'dotfiles-mise-'));
const config = path.join(home, '.config/mise/config.toml');
const env = Object.fromEntries(
  Object.entries(process.env).filter(([key]) => !/^(MISE_|XDG_)/.test(key)),
);
Object.assign(env, {
  HOME: home,
  XDG_CONFIG_HOME: path.join(home, '.config'),
  XDG_DATA_HOME: path.join(home, '.local/share'),
  XDG_CACHE_HOME: path.join(home, '.cache'),
  XDG_STATE_HOME: path.join(home, '.local/state'),
  MISE_OFFLINE: '1',
  MISE_AUTO_INSTALL: '0',
  MISE_TRUSTED_CONFIG_PATHS: home,
});

function mise(...args) {
  return execFileSync('mise', args, { cwd: home, env, encoding: 'utf8' }).trim();
}

function get(key) {
  return mise('config', 'get', '--file', config, key);
}

try {
  fs.mkdirSync(path.dirname(config), { recursive: true });
  fs.copyFileSync(path.join(repo, 'config/.config/mise/config.toml'), config);
  const configs = JSON.parse(mise('config', 'ls', '--json'));
  assert.equal(configs.length, 1);
  assert.equal(configs[0].path, config);

  const tools = [
    'aws-cli', 'copilot', 'fzf', 'gh', 'go', 'java', 'jq', 'mkcert', 'node',
    'npm:corepack', 'pipx', 'python', 'sbt', 'scala', 'unison',
    'conda:git', 'conda:htop', 'conda:tree', 'conda:watch', 'conda:wget',
    'github:guardian/fsbp-tools', 'github:guardian/self-assessment',
    'http:ack', 'http:session-manager-plugin',
  ];
  const macOnly = [
    'github:guardian/fsbp-tools',
    'github:guardian/self-assessment',
    'http:session-manager-plugin',
  ];
  assert.deepEqual(configs[0].tools.sort(), tools.sort());

  assert.deepEqual(JSON.parse(get('tools.java')), ['latest', '21']);
  assert.equal(get('tools.python'), '3.12');
  assert.equal(get('tools.node'), '24');
  for (const tool of ['copilot', 'gh', 'go', 'npm:corepack']) {
    assert.equal(get(`tools.${tool}`), 'latest');
  }
  for (const tool of ['sbt', 'scala']) {
    assert.deepEqual(JSON.parse(get(`tools.${tool}.depends`)), ['java']);
  }
  assert.deepEqual(JSON.parse(get('tools.pipx.depends')), ['python']);
  for (const tool of macOnly) {
    assert.deepEqual(JSON.parse(get(`tools.${tool}.os`)), ['macos']);
  }
  assert.equal(get('tools.github:guardian/fsbp-tools.matching'), 'fsbp-fix_');

  assert.match(get('tools.http:ack.version'), /^\d+\.\d+\.\d+$/);
  assert.equal(get('tools.http:ack.url'), 'https://beyondgrep.com/ack-v{{ version }}');
  assert.match(get('tools.http:ack.checksum'), /^sha256:[a-f0-9]{64}$/);
  assert.equal(get('tools.http:ack.bin'), 'ack');
  assert.match(get('tools.http:session-manager-plugin.version'), /^\d+(\.\d+){3}$/);
  assert.equal(get('tools.http:session-manager-plugin.strip_components'), '1');
  assert.equal(get('tools.http:session-manager-plugin.bin_path'), 'bin');
  for (const [platform, directory] of [['macos-x64', 'mac'], ['macos-arm64', 'mac_arm64']]) {
    const prefix = `tools.http:session-manager-plugin.platforms.${platform}`;
    assert.equal(
      get(`${prefix}.url`),
      `https://session-manager-downloads.s3.amazonaws.com/plugin/{{ version }}/${directory}/sessionmanager-bundle.zip`,
    );
    assert.match(get(`${prefix}.checksum`), /^sha256:[a-f0-9]{64}$/);
  }

  const brewfile = fs.readFileSync(path.join(repo, 'brew/Brewfile'), 'utf8');
  const entries = new Set(
    [...brewfile.matchAll(/^(?:brew|cask|go|npm|tap)\s+"([^"]+)"/gm)].map(match => match[1]),
  );
  const migrated = [
    'ack', 'awscli', 'fzf', 'gh', 'git', 'htop', 'jq', 'mkcert', 'openjdk',
    'openjdk@21', 'pipx', 'python@3.12', 'sbt', 'scala', 'tree', 'watch', 'wget',
    'guardian/devtools/fsbp-fix', 'guardian/devtools/self-assessment',
    'unisonweb/unison/unison-language', 'session-manager-plugin',
    'cmd/go', 'cmd/gofmt', 'corepack', 'guardian/devtools/gu-base',
    'guardian/devtools/gu-scala', 'unisonweb/unison',
  ];
  for (const entry of migrated) {
    assert(!entries.has(entry), `${entry} is still declared in the Brewfile`);
  }
  for (const entry of [
    'mise', 'stow', 'openssl', 'bash-completion', 'coreutils', 'gnupg', 'nginx',
    'nss', 'guardian/devtools/dev-nginx', 'guardian/devtools/ssm', 'gpg-suite',
    'colima', 'ffmpeg', 'nvm', 'docker-desktop',
  ]) {
    assert(entries.has(entry), `${entry} must remain managed by Homebrew`);
  }
  assert(!fs.existsSync(path.join(repo, 'shell/.tool-versions')));
  console.log('Global mise configuration tests passed.');
} finally {
  fs.rmSync(home, { recursive: true });
}
