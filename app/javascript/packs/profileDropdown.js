import { initBlock } from '../profileDropdown/blockButton';
import { initFlag } from '../profileDropdown/flagButton';

function initButtons() {
  initBlock();
  initFlag();
}

window.InstantClick.on('change', () => {
  initButtons();
});

initButtons();
