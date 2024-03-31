const fs = require('fs');
const yaml = require('js-yaml');

const locale = './config/reactions.yml';
const data = fs.readFileSync(locale, 'utf8');
const yamlData = yaml.load(data);

const publicReactionIcons = Object.keys(yamlData)
  .filter(
    (slug) =>
      yamlData[slug].privileged !== true && yamlData[slug].published !== false,
  )
  .map((slug) => {
    const { name, icon, position } = yamlData[slug];

    return `<img data-name="${name}" data-position="${position}" data-slug="${slug}" src="/assets/${icon}.svg" width="18" height="18" />`;
  })
  .join('');

export function reactionImagesSupport() {
  document.body.innerHTML += `<div id="reaction-category-resources" class="hidden" aria-hidden="true">${publicReactionIcons}</div>`;
}
