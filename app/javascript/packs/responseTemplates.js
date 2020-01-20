import initResponseTemplates from '../responseTemplates/responseTemplates';

window.InstantClick.on('change', () => {
  initResponseTemplates();
});

initResponseTemplates();
