import hideBlockedContent from '../contentDisplayPolicy/hideBlockedContent';

window.InstantClick.on('change', () => {
  hideBlockedContent();
});

hideBlockedContent();
