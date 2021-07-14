/* global ActiveXObject */
/* eslint no-undef: "error" */

setTimeout(() => {
  const tokenMeta = document.querySelector("meta[name='csrf-token']"),
    isBot = /bot|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex/i.test(
      navigator.userAgent,
    ), // is crawler
    variantEl = document.getElementById('html-variant-element');
  if (tokenMeta && !isBot) {
    const dataBody = {
      html_variant_id: variantEl.dataset.variantId,
    };
    const csrfToken = tokenMeta.getAttribute('content');
    trackHTMLVariantTrial(dataBody, csrfToken);
    const successLinks = document.querySelectorAll('a,button'); //track all links and button clicks within nav
    for (let i = 0; i < successLinks.length; i++) {
      successLinks[i].addEventListener('click', (e) => {
        e.preventDefault();
        const goTo = e.target.href;
        trackHtmlVariantSuccess(dataBody, csrfToken);
        setTimeout(() => {
          window.location.href = goTo;
        }, 250);
      });
    }
  }
}, 1500);

function trackHTMLVariantTrial(dataBody, csrfToken) {
  const randomNumber = Math.floor(Math.random() * 10); // 1 in 10; Only track 1 in 10 impressions
  if (randomNumber) {
    window.fetch('/html_variant_trials', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(dataBody),
      credentials: 'same-origin',
    });
  }
}

function trackHtmlVariantSuccess(dataBody, csrfToken) {
  window.fetch('/html_variant_successes', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(dataBody),
    credentials: 'same-origin',
  });
}

fetchBaseData();

function fetchBaseData() {
  let xmlhttp;
  if (window.XMLHttpRequest) {
    xmlhttp = new XMLHttpRequest();
  } else {
    xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
  }
  xmlhttp.onreadystatechange = function () {
    if (xmlhttp.readyState == XMLHttpRequest.DONE) {
      const json = JSON.parse(xmlhttp.responseText);
      if (json.token) {
        removeExistingCSRF();
      }
      const meta = document.createElement('meta');
      const metaTag = document.querySelector("meta[name='csrf-token']");
      meta.name = 'csrf-param';
      meta.content = json.param;
      document.head.appendChild(meta);
      metaTag.name = 'csrf-token';
      metaTag.content = json.token;
      document.head.appendChild(metaTag);
      document.body.dataset.loaded = 'true';
    }
  };

  xmlhttp.open('GET', '/async_info/base_data', true);
  xmlhttp.send();
}

function removeExistingCSRF() {
  const csrfTokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfParamMeta = document.querySelector("meta[name='csrf-param']");
  if (csrfTokenMeta && csrfParamMeta) {
    csrfTokenMeta.parentNode.removeChild(csrfTokenMeta);
    csrfParamMeta.parentNode.removeChild(csrfParamMeta);
  }
}
