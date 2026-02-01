const fs = require('fs');
const path = require('path');

console.log('🏗️ Starting build process for FIAP Todo API...');

// Criar diretório dist
const distDir = path.join(__dirname, 'dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

// Copiar arquivos source
const srcDir = path.join(__dirname, 'src');
const files = fs.readdirSync(srcDir);

console.log('📁 Copying source files...');
files.forEach(file => {
  const srcFile = path.join(srcDir, file);
  const distFile = path.join(distDir, file);
  fs.copyFileSync(srcFile, distFile);
  console.log(`✅ Copied ${file} to dist/`);
});

// Copiar package.json (sem devDependencies)
console.log('📦 Creating production package.json...');
const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
const productionPackageJson = {
  name: packageJson.name,
  version: packageJson.version,
  description: packageJson.description,
  main: packageJson.main,
  scripts: {
    start: packageJson.scripts.start
  },
  dependencies: packageJson.dependencies,
  keywords: packageJson.keywords,
  author: packageJson.author,
  license: packageJson.license
};

fs.writeFileSync(
  path.join(distDir, 'package.json'),
  JSON.stringify(productionPackageJson, null, 2)
);
console.log('✅ Created production package.json');

// Criar manifest de build
const manifest = {
  name: 'fiap-todo-api',
  version: process.env.VERSION || '1.0.0',
  buildTime: new Date().toISOString(),
  environment: process.env.NODE_ENV || 'production',
  files: files,
  endpoints: [
    'GET /health',
    'GET /api/todos',
    'POST /api/todos',
    'GET /api/todos/:id',
    'PUT /api/todos/:id',
    'DELETE /api/todos/:id',
    'GET /api/stats'
  ],
  features: [
    'CRUD operations',
    'Filtering and search',
    'Input validation',
    'Rate limiting',
    'Security headers',
    'Error handling'
  ]
};

fs.writeFileSync(
  path.join(distDir, 'manifest.json'), 
  JSON.stringify(manifest, null, 2)
);
console.log('✅ Created build manifest');

// Criar Dockerfile para produção
const dockerfile = `FROM node:20-alpine

WORKDIR /app

# Copiar package.json e instalar dependências
COPY package.json .
RUN npm ci --only=production && npm cache clean --force

# Copiar código da aplicação
COPY . .

# Criar usuário não-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

# Expor porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Comando de inicialização
CMD ["npm", "start"]
`;

fs.writeFileSync(path.join(distDir, 'Dockerfile'), dockerfile);
console.log('✅ Created production Dockerfile');

// Criar README para produção
const readme = `# FIAP Todo API

## 🚀 Quick Start

\`\`\`bash
npm install
npm start
\`\`\`

## 📋 API Endpoints

- \`GET /health\` - Health check
- \`GET /api/todos\` - List all todos
- \`POST /api/todos\` - Create new todo
- \`GET /api/todos/:id\` - Get specific todo
- \`PUT /api/todos/:id\` - Update todo
- \`DELETE /api/todos/:id\` - Delete todo
- \`GET /api/stats\` - Get statistics

## 🐳 Docker

\`\`\`bash
docker build -t fiap-todo-api .
docker run -p 3000:3000 fiap-todo-api
\`\`\`

Built with ❤️ for FIAP CI/CD Course
`;

fs.writeFileSync(path.join(distDir, 'README.md'), readme);
console.log('✅ Created production README');

console.log('🎉 Build completed successfully!');
console.log(`📦 Build artifacts available in: ${distDir}`);
console.log(`🏷️ Version: ${manifest.version}`);
console.log(`⏰ Build time: ${manifest.buildTime}`);
