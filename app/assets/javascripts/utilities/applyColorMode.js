var DARK_COLOR_SCHEME_QUERY = '(prefers-color-scheme: dark)';

function prefersDarkColorScheme() {
  return Boolean(
    window.matchMedia && window.matchMedia(DARK_COLOR_SCHEME_QUERY).matches,
  );
}

function darkColorModeEnabled(bodyClass) {
  if (!bodyClass) {
    return false;
  }

  if (bodyClass.includes('system-theme')) {
    return prefersDarkColorScheme();
  }

  return bodyClass.includes('dark-theme');
}

function applyColorMode(bodyClass) {
  var isDark = darkColorModeEnabled(bodyClass);
  var styleSource = document.getElementById(
    isDark ? 'dark-mode-style' : 'light-mode-style',
  );
  var styleTarget = document.getElementById('body-styles');

  // ten-x-hacker-theme is the marker the iOS app uses for its dark shell.
  document.body.classList.toggle('dark-theme', isDark);
  document.body.classList.toggle('ten-x-hacker-theme', isDark);

  if (styleSource && styleTarget) {
    styleTarget.innerHTML = '<style>' + styleSource.innerHTML + '</style>';
  }

  if (window.ReactNativeWebView) {
    window.ReactNativeWebView.postMessage(
      JSON.stringify({
        action: 'update_color_mode',
        value: isDark ? 'dark' : 'light',
      }),
    );
  }

  return isDark;
}

function watchColorModeChanges() {
  if (!window.matchMedia || window.colorModeWatcherStarted) {
    return;
  }

  var query = window.matchMedia(DARK_COLOR_SCHEME_QUERY);
  var handler = function reapplyColorMode() {
    applyColorMode(document.body.className);
  };

  if (query.addEventListener) {
    query.addEventListener('change', handler);
  } else if (query.addListener) {
    query.addListener(handler);
  }

  window.colorModeWatcherStarted = true;
}

if (typeof globalThis !== 'undefined') {
  globalThis.darkColorModeEnabled = darkColorModeEnabled; // eslint-disable-line no-undef
  globalThis.applyColorMode = applyColorMode; // eslint-disable-line no-undef
  globalThis.watchColorModeChanges = watchColorModeChanges; // eslint-disable-line no-undef
}
