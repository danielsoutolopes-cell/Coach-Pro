const fs = require('fs');
const path = require('path');

const f = path.join(__dirname, 'android', 'gradle.properties');
let c = fs.readFileSync(f, 'utf-8');

c = c.replace(/newArchEnabled\s*=\s*false/g, 'newArchEnabled=true');
if (!c.includes('newArchEnabled=true')) c += '\nnewArchEnabled=true\n';

fs.writeFileSync(f, c);
console.log('✅ Nova Arquitetura ativada no gradle.properties!');