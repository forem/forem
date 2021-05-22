import { hideBlockedContent } from '../contentDisplayPolicy/hideBlockedContent';
import { initHiddenComments } from '../contentDisplayPolicy/initHiddenComments';
import { embedGists } from '../utilities/gist';

function handleEmbedGists() {
  const targetNode = document.querySelector('#articles-list');
  targetNode && embedGists(targetNode);
}

window.InstantClick.on('change', () => {
  hideBlockedContent();
  initHiddenComments();
  handleEmbedGists();
});

hideBlockedContent();
initHiddenComments();
handleEmbedGists();
