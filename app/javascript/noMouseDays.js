const dayOfWeek = new Date().getDay();

// We only want to disable mouse usage
// on Fridays.
if (dayOfWeek === 5) {
  import('no-mouse-days');
}
