import { embedGists } from '../utilities/gist';

function handleEmbedGists() {
  const targetNode = document.querySelector('#articles-list');
  targetNode && embedGists(targetNode);
}

window.InstantClick.on('change', () => {
  handleEmbedGists();
});

handleEmbedGists();
