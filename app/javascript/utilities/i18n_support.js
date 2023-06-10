//Load the package
const fs = require('fs');
const yaml = require('js-yaml');

//Read the Yaml file
const locale = './config/locales/en.yml';
const data = fs.readFileSync(locale, 'utf8');
const yamlData = yaml.load(data);

document.body.innerHTML += `<div id="i18n-translations"></div>`;
document.getElementById('i18n-translations').dataset.translations =
  JSON.stringify(yamlData);

export function i18nSupport() {
  // this function doesn't really do anything
  // so long as you load this module before the 'locale' utility
  // the div will be there when it needs it
}
