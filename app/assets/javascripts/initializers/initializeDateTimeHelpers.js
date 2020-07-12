/* global localizeTimeElements */

'use strict';

function initializeDateTimeHelpers() {
  const dates = document.querySelectorAll('time.date');

  localizeTimeElements(dates, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  });
}
