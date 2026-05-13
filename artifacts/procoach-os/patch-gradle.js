const fs = require('fs');
const path = require('path');

const f = path.join(__dirname, 'android', 'app', 'build.gradle');
let c = fs.readFileSync(f, 'utf-8');

if (!c.includes('entryFile = file("../../index.js")')) {
  if (c.includes('root = file("../../")')) {
    // O PowerShell adicionou o root, mas faltou o entryFile. Vamos colocar logo abaixo!
    c = c.replace('root = file("../../")', 'root = file("../../")\n    entryFile = file("../../index.js")');
  } else {
    // Nenhum dos dois existe, insere ambos.
    c = c.replace(/react\s*\{/, 'react {\n    root = file("../../")\n    entryFile = file("../../index.js")');
  }
  fs.writeFileSync(f, c);
  console.log('✅ build.gradle corrigido com sucesso (Forçado)!');
} else {
  console.log('⚠️ O arquivo já está 100% correto.');
}