"use strict";

// helpers to safely encode/decode Unicode to base64
function base64EncodeUnicode(str) {
  // https://developer.mozilla.org/en-US/docs/Glossary/Base64#the_unicode_problem
  return btoa(
    encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, (_, p1) =>
      String.fromCharCode("0x" + p1),
    ),
  );
}

function base64DecodeUnicode(str) {
  return decodeURIComponent(
    atob(str)
      .split("")
      .map((c) => {
        return "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2);
      })
      .join(""),
  );
}

// derive a cookie domain that works across subdomains; skip for localhost
function getCrossSubdomainCookieDomain() {
  const host = window.location.hostname; // e.g., "sub.example.com"
  if (
    host === "localhost" ||
    /^\d+\.\d+\.\d+\.\d+$/.test(host) /* IP address */
  ) {
    return null; // don't set domain for localhost or plain IP
  }
  const parts = host.split(".");
  if (parts.length <= 2) {
    return "." + host; // e.g., example.com -> .example.com
  }
  // take last two (e.g., example.com) but prefix dot so subdomains share
  return "." + parts.slice(-2).join(".");
}

function setCookie(name, value, days, domain) {
  let cookie = `${encodeURIComponent(name)}=${encodeURIComponent(
    value,
  )}; Path=/; Max-Age=${days * 24 * 60 * 60}; Secure; SameSite=None`;
  if (domain) {
    cookie += `; Domain=${domain}`;
  }
  document.cookie = cookie;
}

function getCookie(name) {
  const match = document.cookie.match(
    new RegExp("(^|; )" + name.replace(/([.*+?^${}()|[\]\\])/g, "\\$1") + "=([^;]*)"),
  );
  return match ? decodeURIComponent(match[2]) : null;
}

function browserStoreCache(action, userData) {
  try {
    switch (action) {
      case "set": {
        // parse incoming userData (assumed JSON string or object)
        let userObj;
        if (typeof userData === "string") {
          userObj = JSON.parse(userData);
        } else {
          userObj = { ...userData };
        }

        // remove reading_list_ids completely
        delete userObj.reading_list_ids;

        // persist to localStorage
        const sanitizedString = JSON.stringify(userObj);
        localStorage.setItem("current_user", sanitizedString);
        if (userObj.config_body_class) {
          localStorage.setItem("config_body_class", userObj.config_body_class);
        }

        // set cross-subdomain cookie: base64-encoded so it can be decoded
        if (navigator.cookieEnabled) {
          const encoded = base64EncodeUnicode(sanitizedString);
          const domain = getCrossSubdomainCookieDomain();
          setCookie("current_user", encoded, 7, domain); // expires in 7 days
        }
        break;
      }
      case "remove":
        localStorage.removeItem("current_user");
        // also remove cookie (set Max-Age=0)
        const domain = getCrossSubdomainCookieDomain();
        setCookie("current_user", "", -1, domain);
        break;
      default:
        return localStorage.getItem("current_user");
    }
  } catch (err) {
    if (navigator.cookieEnabled) {
      browserStoreCache("remove");
    }
  }
  return undefined;
}
