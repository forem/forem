console.log("deploying via custom script")
console.log("deploying via custom script")
console.log("deploying via custom script")
console.log("deploying via custom script")
import { exec } from 'child_process';
const site = process.env.URL;
console.log(site);
const subdomain = site.split('/')[site.split('/').length - 1];

let buildCommand;
switch (subdomain) {
  case 'docs.dev.to':
    buildCommand = 'npm install -g gitdocs@latest && gitdocs build';
    break;
  case 'storybook.dev.to':
    buildCommand = 'npm run build-storybook';
    break;
  default:
    throw `Domain ${domain} is invalid`;
}

async function execute(command) {
  return await exec(command, function(error, stdout, stderr) {
    if (error) {
      throw error;
    }
    console.log(`site: ${site}`);
    console.log(`domain: ${domain}`);
    console.log(stdout);
  });
}

execute(buildCommand);
