import { loadResponseTemplates } from '../responseTemplates/responseTemplates';

window.InstantClick.on('change', () => {
  loadResponseTemplates();
});

loadResponseTemplates();
