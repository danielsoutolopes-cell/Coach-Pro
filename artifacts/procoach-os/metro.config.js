const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

// Encontra a raiz do aplicativo e a raiz do monorepo
const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

// 1. Observa todos os arquivos na raiz do monorepo
config.watchFolders = [workspaceRoot];

// 2. Diz ao Metro onde procurar os pacotes importados (node_modules)
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];

module.exports = config;