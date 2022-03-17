const [firstFlashDismissBtn] =
  document.getElementsByClassName('js-flash-close-btn');

// This allows screen reader users to become aware of the message (as well as bringing focus to the top of the main content).
// (we don't use aria-live or role="alert" on the message text as these are not reliably announced for content that exists from page load)
firstFlashDismissBtn?.focus();
