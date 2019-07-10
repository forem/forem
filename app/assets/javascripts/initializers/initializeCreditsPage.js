/* global localizeTimeElements */
function initializeCreditsPage() {
  const datetimes = document.querySelectorAll('.ledger time');

  localizeTimeElements(datetimes, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}
