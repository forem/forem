/* global localizeTimeElements */

'use strict';

function initializeDateHelpers() {
  // Date without year: Jul 12
  localizeTimeElements(document.querySelectorAll('time.date-no-year'), {
    month: 'short',
    day: 'numeric',
  });

  // Full date: Jul 12, 2020
  localizeTimeElements(document.querySelectorAll('time.date'), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  // Date with short year: Jul 12 '20
  localizeTimeElements(document.querySelectorAll('time.date-short-year'), {
    year: '2-digit',
    month: 'short',
    day: 'numeric',
  });
}
