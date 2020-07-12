/* global localizeTimeElements */

'use strict';

function initializeDateHelpers() {
  // Date without year: Jul 12
  localizeTimeElements(document.querySelectorAll('time.date-no-year'), {
    month: 'short',
    day: '2-digit',
  });

  // Full date: Jul 12, 2020
  localizeTimeElements(document.querySelectorAll('time.date'), {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  });
}
