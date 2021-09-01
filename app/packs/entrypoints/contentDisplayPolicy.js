import { hideBlockedContent } from '../contentDisplayPolicy/hideBlockedContent';
import { initHiddenComments } from '../contentDisplayPolicy/initHiddenComments';

window.InstantClick.on('change', () => {
  hideBlockedContent();
  initHiddenComments();
});

hideBlockedContent();
initHiddenComments();
