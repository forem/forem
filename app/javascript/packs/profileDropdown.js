import initBlock from '../profileDropdown/blockButton';
import initAbuseButton from '../profileDropdown/abuseButton';

window.InstantClick.on('change', () => {
  initBlock();
  initAbuseButton();
});

initBlock();
initAbuseButton();
