/*
  global initializeLocalStorageRender, initializeBodyData,
  initializeAllTagEditButtons, initializeBaseUserData,
  initializeReadingListIcons, initializeFavoritedMarkers,
  initializeBillboardVisibility,
  initializeCreditsPage,
  initializeOnboardingTaskCard,
  initScrolling, nextPage:writable,
  fetching:writable, done:writable, initializePaymentPointers,
  initializeBroadcast
*/

var commentsPageBundlePromise = null;

function pageNeedsCommentsBundle() {
  return Boolean(
    document.getElementById('comments-container') ||
      document.getElementById('notifications-container') ||
      document.querySelector(
        '.comment-form, .comment-textarea, .js-comment-wrapper',
      ),
  );
}

function loadCommentsPageBundle() {
  if (window.__commentsPageBundleLoaded) {
    return Promise.resolve();
  }
  if (commentsPageBundlePromise) {
    return commentsPageBundlePromise;
  }
  var meta = document.querySelector('meta[name="comments-page-script"]');
  var scriptSrc = meta && meta.getAttribute('content');
  if (!scriptSrc) {
    return Promise.resolve();
  }
  var existingScript = document.querySelector('script[src="' + scriptSrc + '"]');
  commentsPageBundlePromise = new Promise(function (resolve) {
    if (existingScript) {
      existingScript.addEventListener(
        'load',
        function () {
          resolve();
        },
        { once: true },
      );
      existingScript.addEventListener(
        'error',
        function () {
          existingScript.remove();
          commentsPageBundlePromise = null;
          resolve();
        },
        { once: true },
      );
      return;
    }
    var script = document.createElement('script');
    script.src = scriptSrc;
    script.defer = true;
    script.onload = function () {
      resolve();
    };
    script.onerror = function () {
      script.remove();
      commentsPageBundlePromise = null;
      resolve();
    };
    document.head.appendChild(script);
  });
  return commentsPageBundlePromise;
}

function runCommentsPageInitializer() {
  if (
    window.__commentsPageBundleLoaded &&
    typeof window.initializeCommentsPage === 'function' &&
    !window.initializeCommentsPage.__isLoaderStub
  ) {
    window.initializeCommentsPage();
    return;
  }
  if (!pageNeedsCommentsBundle()) {
    return;
  }
  loadCommentsPageBundle().then(function () {
    if (
      typeof window.initializeCommentsPage === 'function' &&
      !window.initializeCommentsPage.__isLoaderStub
    ) {
      window.initializeCommentsPage();
    }
  });
}

if (!window.__commentsPageBundleLoaded) {
  window.initializeCommentsPage = runCommentsPageInitializer;
  window.initializeCommentsPage.__isLoaderStub = true;

  [
    'handleFocus',
    'handleKeyUp',
    'handleKeyDown',
    'handleChange',
    'validateField',
    'handleCommentSubmit',
    'handleFormClose',
  ].forEach(function (fnName) {
    if (typeof window[fnName] !== 'function') {
      window[fnName] = function (event, arg) {
        var self = this;
        if (
          fnName === 'handleCommentSubmit' &&
          event &&
          typeof event.preventDefault === 'function'
        ) {
          event.preventDefault();
        }
        loadCommentsPageBundle().then(function () {
          if (typeof window[fnName] === 'function' && !window[fnName].__isStub) {
            window[fnName].call(self, event, arg);
          }
        });
      };
      window[fnName].__isStub = true;
    }
  });
}

function callInitializers() {
  initializePaymentPointers();
  runCommentsPageInitializer();
  initializeCreditsPage();
  initializeOnboardingTaskCard();
}

function initializePage() {
  initializeLocalStorageRender();
  initializeBodyData();

  var waitingForDataLoad = setInterval(function wait() {
    if (document.body.getAttribute('data-loaded') === 'true') {
      clearInterval(waitingForDataLoad);
      if (document.body.getAttribute('data-user-status') === 'logged-in') {
        initializeBaseUserData();
        initializeAllTagEditButtons();
        initializeOnboardingTaskCard();
      }
      initializeBroadcast();
      initializeReadingListIcons();
      initializeFavoritedMarkers();
      initializeBillboardVisibility();
      if (document.getElementById('sidebar-additional')) {
        document.getElementById('sidebar-additional').classList.add('showing');
      }
    }
  }, 1);

  callInitializers();

  nextPage = 0;
  fetching = false;
  done = false;
  setTimeout(function undone() {
    done = false;
  }, 300);
  if (!initScrolling.called) {
    initScrolling();
  }
}
