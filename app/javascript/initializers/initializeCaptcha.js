export function createCaptchaInitializer({
  apiName,
  selector,
  callbackName,
  scriptUrl,
  options,
}) {
  const widgets = new Map();
  let apiPromise;

  function loadApi() {
    if (!apiPromise) {
      apiPromise = new Promise((resolve, reject) => {
        if (typeof window[apiName]?.render === 'function') {
          resolve(window[apiName]);
          return;
        }

        window[callbackName] = () => {
          delete window[callbackName];
          resolve(window[apiName]);
        };
        const script = document.createElement('script');
        script.src = scriptUrl;
        script.async = true;
        script.defer = true;
        script.onerror = () => {
          delete window[callbackName];
          script.remove();
          apiPromise = null;
          reject(new Error(`Unable to load ${apiName}`));
        };
        document.head.appendChild(script);
      });
    }

    return apiPromise;
  }

  return async function initializeCaptcha() {
    widgets.forEach((widgetId, container) => {
      if (!container.isConnected) {
        window[apiName].remove(widgetId);
        container.replaceChildren();
        widgets.delete(container);
      }
    });

    if (!document.querySelector(selector)) return;

    try {
      const api = await loadApi();
      document.querySelectorAll(selector).forEach((container) => {
        if (widgets.has(container)) return;

        container.replaceChildren();
        const widgetId = api.render(container, options(container));
        widgets.set(container, widgetId);
      });
    } catch {
      console.error(`Unable to initialize ${apiName}`);
    }
  };
}
