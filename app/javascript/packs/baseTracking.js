function initializeBaseTracking() {
  trackGoogleAnalytics3();
  trackGoogleAnalytics4();
  trackCustomImpressions();
}
  
function trackGoogleAnalytics3() {
  let wait = 0;
  let addedGA = false;
  const gaTrackingCode = document.body.dataset.gaTracking;
  if (gaTrackingCode) {
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

        gtag('js', new Date());
        gtag('config', ga4MeasurementCode, { 'anonymize_ip': true });
        clearInterval(waitingOnGA4);
      }
      if (wait > 85) {
        clearInterval(waitingOnGA4);
        //The gem we're using server-side (Staccato) is not yet compatible with the Google Analytics 4 tracking code.
        //More details: https://github.com/tpitale/staccato/issues/97 %>
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
    viewport_size: `${h  }x${  w}`,
    screen_resolution: `${screenH  }x${  screenW}`,
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

initializeBaseTracking();