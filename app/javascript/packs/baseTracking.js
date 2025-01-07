/*eslint-disable prefer-rest-params*/
/* global isTouchDevice */

function initializeBaseTracking() {
  showCookieConsentBanner();
  trackGoogleAnalytics3();
  trackGoogleAnalytics4();
  trackCustomImpressions();
  trackEmailClicks();
}

// Google Anlytics 3 is deprecated, and mostly not supported, but some sites may still be using it for now.
function trackGoogleAnalytics3() {
  let wait = 0;
  let addedGA = false;
  const gaTrackingCode = document.body.dataset.gaTracking;
  if (gaTrackingCode && localStorage.getItem('cookie_status') === 'allowed') {
    const waitingOnGA = setInterval(() => {
      if (!addedGA) {
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                                  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
      }
      addedGA = true;
      wait++;
      if (window.ga && ga.create) {
        ga('create', gaTrackingCode, 'auto');
        ga('set', 'anonymizeIp', true);
        ga('send', 'pageview', location.pathname + location.search);
        clearInterval(waitingOnGA);
      }
      if (wait > 85) {
        clearInterval(waitingOnGA);
        fallbackActivityRecording();
      }
    }, 25);
    eventListening();
  } else if (gaTrackingCode) {
    fallbackActivityRecording();
  }
}

function trackGoogleAnalytics4() {
  let wait = 0;
  let addedGA4 = false;
  const ga4MeasurementCode = document.body.dataset.ga4TrackingId;
  if (ga4MeasurementCode) {
    const waitingOnGA4 = setInterval(() => {
      if (!addedGA4) {
        //Dynamically add the Google Analytics 4 script tag
        const script = document.createElement('script');
        script.src = `//www.googletagmanager.com/gtag/js?id=${  ga4MeasurementCode}`;
        script.async = true;
        document.head.appendChild(script);
      }
      addedGA4 = true;
      wait++;
      if (window.google_tag_manager) {
        //Define the gtag function and call it. Adapted from https://stackoverflow.com/questions/22716542/google-analytics-code-explanation %>
        window.dataLayer = window.dataLayer || [];
        // eslint-disable-next-line no-inner-declarations
        function gtag(){window.dataLayer.push(arguments);}

        window['gtag'] = window['gtag'] || function () {
          window.dataLayer.push(arguments)
        }
        const consent = localStorage.getItem('cookie_status') === 'allowed' ? 'granted' : 'denied';
        gtag('js', new Date());
        gtag('config', ga4MeasurementCode, { 'anonymize_ip': true });
        gtag('consent', 'default', {
          'ad_storage': consent,
          'analytics_storage': consent
        });
        clearInterval(waitingOnGA4);
      }
      if (wait > 85) {
        clearInterval(waitingOnGA4);
        fallbackActivityRecording();
      }
    }, 25);
    eventListening();
  }
}


function fallbackActivityRecording() {
  const tokenMeta = document.querySelector("meta[name='csrf-token']")
  if (!tokenMeta) {
    return
  }
  const csrfToken = tokenMeta.getAttribute('content')
  const w = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
  const h = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
  const screenW = window.screen.availWidth;
  const screenH = window.screen.availHeight;
  const dataBody = {
    path: location.pathname + location.search,
    user_language: navigator.language,
    referrer: document.referrer,
    user_agent: navigator.userAgent,
    viewport_size: `${h}x${w}`,
    screen_resolution: `${screenH}x${screenW}`,
    document_title: document.title,
    document_encoding: document.characterSet,
    document_path: location.pathname + location.search,
  };
  window.fetch('/fallback_activity_recorder', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken,
    },
    body: JSON.stringify(dataBody),
    credentials: 'same-origin'
  });
}

function eventListening(){
  const registerNowButt = document.getElementById("cta-comment-register-now-link");
  if (registerNowButt) {
    registerNowButt.onclick = function(){
      ga('send', 'event', 'click', 'register-now-click', null, null);
    }
  }
}

// eslint-disable-next-line no-unused-vars
function ga4eventListening(){
  const registerNowButt = document.getElementById("cta-comment-register-now-link");
  if (registerNowButt) {
    registerNowButt.onclick = function(){
      gtag('event', 'register-now-click' );
    }
  }
}

function checkUserLoggedIn() {
  const {body} = document;
  if (!body) {
    return false;
  }

  return body.getAttribute('data-user-status') === 'logged-in';
}

function trackCustomImpressions() {
  setTimeout(()=> {
    const ArticleElement = document.getElementById('article-body') || document.getElementById('comment-article-indicator');
    const tokenMeta = document.querySelector("meta[name='csrf-token']")
    const isBot = /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(navigator.userAgent) // is crawler
    // eslint-disable-next-line no-unused-vars
    const windowBigEnough =  window.innerWidth > 1023

    // page view
    if (ArticleElement && tokenMeta && !isBot) {
      // See https://github.com/forem/forem/blob/main/app/controllers/page_views_controller.rb
      //
      // If you change the 10, you should look at the PageViewsController as well.
      const randomNumber = Math.floor(Math.random() * 10); // 1 in 10; Only track 1 in 10 impressions
      if (!checkUserLoggedIn() && randomNumber != 1) {
        return;
      }
      const dataBody = {
        article_id: ArticleElement.dataset.articleId,
        referrer: document.referrer,
        user_agent: navigator.userAgent,
      };
      const csrfToken = tokenMeta.getAttribute('content');
      trackPageView(dataBody, csrfToken);
      let timeOnSiteCounter = 0;
      const timeOnSiteInterval = setInterval(()=> {
        timeOnSiteCounter++
        const ArticleElement = document.getElementById('article-body') || document.getElementById('comment-article-indicator');
        if (ArticleElement && checkUserLoggedIn()) {
          trackFifteenSecondsOnPage(ArticleElement.dataset.articleId, csrfToken);
        } else {
          clearInterval(timeOnSiteInterval);
        }
        if ( timeOnSiteCounter > 118 ) {
          clearInterval(timeOnSiteInterval);
        }
      }, 15000)
    }

  }, 1800)
}

function trackEmailClicks() {
  const urlParams = new URLSearchParams(window.location.search);

    if (urlParams.get('ahoy_click') === 'true' && urlParams.get('t') && urlParams.get('s') && urlParams.get('u')){
      const dataBody = {
        t: urlParams.get('t'),
        c: urlParams.get('c'),
        u: decodeURIComponent(urlParams.get('u')),
        s: urlParams.get('s'),
        bb: urlParams.get('bb'),
      };
      window.fetch('/ahoy/email_clicks', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(dataBody),
        credentials: 'same-origin'
      });
      // Remove t,c,u,s params and ahoy_click param from url without modifying the history
      urlParams.delete('t');
      urlParams.delete('c');
      urlParams.delete('u');
      urlParams.delete('s');
      urlParams.delete('ahoy_click');
      urlParams.delete('bb');
      const newUrl = `${window.location.pathname  }?${  urlParams.toString()}`;
      window.history.replaceState({}, null, newUrl);
    }
}

function showCookieConsentBanner() {
  // if current url includes ?cookietest=true
  if (shouldShowCookieBanner()) {
    // show modal with cookie consent
    const cookieDiv = document.getElementById('cookie-consent');

    if (cookieDiv && localStorage.getItem('cookie_status') !== 'allowed' && localStorage.getItem('cookie_status') !== 'dismissed') {
      cookieDiv.innerHTML = `
        <div class="cookie-consent-modal">
          <div class="cookie-consent-modal__content">
            <p>
              <strong>Some content on our site requires cookies for personalization.</strong>
            </p>
            <p>
              Read our full <a href="/privacy">privacy policy</a> to learn more.
            </p>
            <div class="cookie-consent-modal__actions">
              <button class="c-btn c-btn--secondary" id="cookie-dismiss">
                Dismiss
              </button>
              <button class="c-btn c-btn--primary" id="cookie-accept">
                Accept Cookies
              </button>
            </div
          </div>
        </div>
      `;

      document.getElementById('cookie-accept').onclick = (() => {
        localStorage.setItem('cookie_status', 'allowed');
        cookieDiv.style.display = 'none';
        if (window.gtag) {
          gtag('consent', 'update', {
            'ad_storage': 'granted',
            'analytics_storage': 'granted'
          });
        }
      });

      document.getElementById('cookie-dismiss').onclick = (() => {
        localStorage.setItem('cookie_status', 'dismissed');
        cookieDiv.style.display = 'none';
      });
    }
  }
}

function shouldShowCookieBanner() {
  const { userStatus, cookieBannerUserContext, cookieBannerPlatformContext } = document.body.dataset;
  function determineActualPlatformContext() {
    if (navigator.userAgent.includes('DEV-Native')) {
      return 'mobile_app'
    } else if (isTouchDevice()) {
      return 'mobile_web'
    }
    return 'desktop_web'
  }

  // Determine the actual platform context
  const actualPlatformContext = determineActualPlatformContext();

  // Check if either user or platform context is set to 'off'
  if (cookieBannerUserContext === 'off' || cookieBannerPlatformContext === 'off') {
    return false;
  }

  // Check based on user status
  const showForUserContext = (userStatus === 'logged-in' && cookieBannerUserContext === 'all') ||
                             (userStatus !== 'logged-in' && cookieBannerUserContext !== 'off');

  // Check based on platform context
  const showForPlatformContext = (cookieBannerPlatformContext === 'all') ||
                                 (cookieBannerPlatformContext === 'all_web' && ['desktop_web', 'mobile_web'].includes(actualPlatformContext)) ||
                                 (cookieBannerPlatformContext === actualPlatformContext);

  // Return true if both user context and platform context conditions are met
  return showForUserContext && showForPlatformContext;
}

function trackPageView(dataBody, csrfToken) {
  window.fetch('/page_views', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(dataBody),
    credentials: 'same-origin',
  })
}

function trackFifteenSecondsOnPage(articleId, csrfToken) {
  window.fetch(`/page_views/${  articleId}`, {
    method: 'PATCH',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  }).catch((error) => console.error(error))
}

window.InstantClick.on('change', () => {
  initializeBaseTracking();
});
initializeBaseTracking();
