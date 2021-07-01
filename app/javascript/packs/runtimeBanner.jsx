import { h, render } from 'preact';
import { RuntimeBanner } from '../runtimeBanner';

function loadElement() {
  const container = document.getElementById('runtime-banner-container');
  if (container) {
    render(<RuntimeBanner />, container);
  }
}

window.InstantClick?.on('change', () => {
  loadElement();
});

loadElement();
