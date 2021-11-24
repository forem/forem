import { h, render } from 'preact';
import { RuntimeBanner } from '../runtimeBanner';
import { waitOnBaseData } from '../utilities/waitOnBaseData';

function loadElement() {
  const container = document.getElementById('runtime-banner-container');
  if (container) {
    render(<RuntimeBanner />, container);
  }
}

// This pack relies on the same logic as `packs/listings` & `packs/Chat`. The
// banner lives in every page (including the main feed) and a race condition
// occurs when the page initializes for the first time or when signing out (no
// cache request). In order to avoid this we defer the initialization until the
// page is actually ready.
waitOnBaseData()
  .then(() => {
    window.InstantClick.on('change', () => {
      loadElement();
    });

    loadElement();
  })
  .catch((error) => {
    Honeybadger.notify(error);
  });
