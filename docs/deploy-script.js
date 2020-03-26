const exec = require('child_process').exec;
const subdomain = process.env.subdomain;

let buildCommand;
switch (subdomain) {
  case 'docs':
    buildCommand = 'make';
    break;
  case 'storybook':
    buildCommand = 'cd .. && npm install && npm run build-storybook';
    break;
  default:
    throw `Subdomain ${subdomain} is invalid`;
}

async function execute(command) {
  return await exec(command, function(error, stdout, stderr) {
    if (error) {
      throw error;
    }
    console.log(`domain: ${subdomain}`);
    console.log(stdout);
  });
}

execute(buildCommand);
