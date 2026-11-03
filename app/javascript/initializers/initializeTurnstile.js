const widgets = new Map();
let apiPromise;

function loadTurnstile() {
  if (!apiPromise) {
    apiPromise = new Promise((resolve, reject) => {
      if (typeof window.turnstile?.render === 'function') {
        resolve(window.turnstile);
        return;
      }

      window.onForemTurnstileLoad = () => {
        delete window.onForemTurnstileLoad;
        resolve(window.turnstile);
      };
      const script = document.createElement('script');
      script.src =
        'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=onForemTurnstileLoad';
      script.async = true;
      script.defer = true;
      script.onerror = () => {
        delete window.onForemTurnstileLoad;
        script.remove();
        apiPromise = null;
        reject(new Error('Unable to load Cloudflare Turnstile'));
      };
      document.head.appendChild(script);
    });
  }

  return apiPromise;
}

export async function initializeTurnstile() {
  widgets.forEach((widgetId, container) => {
    if (!container.isConnected) {
      window.turnstile.remove(widgetId);
      container.replaceChildren();
      widgets.delete(container);
    }
  });

  if (!document.querySelector('.cf-turnstile')) return;

  try {
    const turnstile = await loadTurnstile();
    document.querySelectorAll('.cf-turnstile').forEach((container) => {
      if (widgets.has(container)) return;

      container.replaceChildren();
      const widgetId = turnstile.render(container, {
        sitekey: container.dataset.sitekey,
      });
      widgets.set(container, widgetId);
    });
  } catch {
    console.error('Unable to initialize Cloudflare Turnstile');
  }
}
