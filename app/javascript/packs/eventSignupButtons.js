import { getInstantClick } from '../topNavigation/utilities';

let observer;

const updateButtonState = (button, isSignedUp) => {
  button.setAttribute('data-signed-up', isSignedUp ? 'true' : 'false');
  button.setAttribute('aria-pressed', isSignedUp ? 'true' : 'false');

  const signedUpClass = button.dataset.signedUpClass;
  const unsignedUpClass = button.dataset.unsignedUpClass;

  if (signedUpClass) {
    signedUpClass.split(' ').forEach((cls) => {
      if (cls) {
        if (isSignedUp) {
          button.classList.add(cls);
        } else {
          button.classList.remove(cls);
        }
      }
    });
  }

  if (unsignedUpClass) {
    unsignedUpClass.split(' ').forEach((cls) => {
      if (cls) {
        if (!isSignedUp) {
          button.classList.add(cls);
        } else {
          button.classList.remove(cls);
        }
      }
    });
  }

  const template = isSignedUp
    ? button.querySelector('template[data-signed-up-html]')
    : button.querySelector('template[data-unsigned-up-html]');

  if (template) {
    // Clear non-template nodes
    Array.from(button.childNodes).forEach((child) => {
      if (child.tagName !== 'TEMPLATE') {
        button.removeChild(child);
      }
    });
    // Append clone of template content
    button.appendChild(template.content.cloneNode(true));
  }
};

const fetchStatuses = () => {
  const buttons = document.querySelectorAll('[data-event-signup-button="true"]:not([data-fetched])');
  if (buttons.length === 0) return;

  buttons.forEach((button) => {
    button.setAttribute('data-fetched', 'true');
  });

  const userStatus = document.body.getAttribute('data-user-status');
  if (userStatus === 'logged-out') {
    buttons.forEach((button) => updateButtonState(button, false));
    return;
  }

  const eventButtons = {};
  buttons.forEach((button) => {
    const nameSlug = button.dataset.eventNameSlug;
    const variationSlug = button.dataset.eventVariationSlug;
    if (!nameSlug || !variationSlug) return;
    const key = `${nameSlug}/${variationSlug}`;
    if (!eventButtons[key]) {
      eventButtons[key] = [];
    }
    eventButtons[key].push(button);
  });

  Object.keys(eventButtons).forEach((key) => {
    const [nameSlug, variationSlug] = key.split('/');
    fetch(`/events/${nameSlug}/${variationSlug}/signup_status`, {
      headers: {
        Accept: 'application/json',
      },
    })
      .then((res) => {
        if (!res.ok) throw new Error('Status check failed');
        return res.json();
      })
      .then((data) => {
        eventButtons[key].forEach((button) => {
          updateButtonState(button, data.signed_up);
        });
      })
      .catch((err) => {
        console.error('Error fetching signup status:', err);
      });
  });
};

const handleEventSignupClick = (e) => {
  const button = e.target.closest('[data-event-signup-button="true"]');
  if (!button) return;

  e.preventDefault();

  const userStatus = document.body.getAttribute('data-user-status');
  if (userStatus === 'logged-out') {
    if (typeof window.showLoginModal === 'function') {
      window.showLoginModal({ trigger: 'event_signup_button' });
    } else {
      window.location.href = `/signup?return_to=${encodeURIComponent(
        window.location.pathname + window.location.search
      )}`;
    }
    return;
  }

  const nameSlug = button.dataset.eventNameSlug;
  const variationSlug = button.dataset.eventVariationSlug;
  if (!nameSlug || !variationSlug) return;

  const isSignedUp = button.getAttribute('data-signed-up') === 'true';

  if (isSignedUp) {
    const confirmMsg = button.dataset.signupConfirmMessage;
    if (confirmMsg && !window.confirm(confirmMsg)) {
      return;
    }
  }

  button.disabled = true;

  const csrfToken =
    document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || '';

  const method = isSignedUp ? 'DELETE' : 'POST';

  fetch(`/events/${nameSlug}/${variationSlug}/signup.json`, {
    method,
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
  })
    .then((res) => {
      if (!res.ok) throw new Error('Signup request failed');
      return res.json();
    })
    .then((data) => {
      const matchingButtons = document.querySelectorAll(
        `[data-event-signup-button="true"][data-event-name-slug="${nameSlug}"][data-event-variation-slug="${variationSlug}"]`
      );
      matchingButtons.forEach((btn) => {
        updateButtonState(btn, data.signed_up);
      });
    })
    .catch((err) => {
      console.error('Error during event signup:', err);
      alert('Something went wrong. Please try again.');
    })
    .finally(() => {
      const matchingButtons = document.querySelectorAll(
        `[data-event-signup-button="true"][data-event-name-slug="${nameSlug}"][data-event-variation-slug="${variationSlug}"]`
      );
      matchingButtons.forEach((btn) => {
        btn.disabled = false;
      });
    });
};

const setupEventSignupFunctionality = () => {
  fetchStatuses();

  if (observer) {
    observer.disconnect();
  }

  observer = new MutationObserver((mutationsList) => {
    let hasNewButtons = false;
    for (const mutation of mutationsList) {
      if (mutation.type === 'childList') {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            if (
              node.matches('[data-event-signup-button="true"]') ||
              node.querySelector('[data-event-signup-button="true"]')
            ) {
              hasNewButtons = true;
              break;
            }
          }
        }
      }
      if (hasNewButtons) break;
    }
    if (hasNewButtons) {
      fetchStatuses();
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });
};

const listenForEventSignupClicks = () => {
  if (document.body.dataset.eventSignupHandlerInitialized === 'true') {
    return;
  }
  document.body.addEventListener('click', handleEventSignupClick);
  document.body.dataset.eventSignupHandlerInitialized = 'true';
};

// Initial setup
if (window.eventSignupCleanup) {
  window.eventSignupCleanup();
}

window.eventSignupCleanup = () => {
  if (observer) {
    observer.disconnect();
  }
  document.body.removeEventListener('click', handleEventSignupClick);
  document.body.removeAttribute('data-event-signup-handler-initialized');
};

listenForEventSignupClicks();

if (document.readyState !== 'loading') {
  setupEventSignupFunctionality();
} else {
  document.addEventListener('DOMContentLoaded', setupEventSignupFunctionality);
}

getInstantClick().then((ic) => {
  ic.on('change', setupEventSignupFunctionality);
});

window.addEventListener('beforeunload', () => {
  if (observer) {
    observer.disconnect();
  }
});
