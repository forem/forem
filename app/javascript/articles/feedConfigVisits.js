import { createEventId } from '../utilities/createEventId';

const MAX_ATTEMPTS = 6;
const REQUEST_TIMEOUT = 10 * 1000;

// Visibility transitions, rather than a timer, define visits. A document left
// open in the foreground must never generate periodic return credit.
export class FeedConfigVisitTracker {
  constructor(token, isCurrent) {
    this.token = token;
    this.isCurrent = isCurrent;
    this.pending = null;
    this.inFlight = false;
    this.nextVisitAt = 0;
    this.nextAttemptAt = 0;
    this.stopped = false;
    this.onVisible = () => this.visit();
    this.onOnline = () => {
      if (this.pending) this.send();
    };
  }

  start() {
    document.addEventListener('visibilitychange', this.onVisible);
    window.addEventListener('pageshow', this.onVisible);
    window.addEventListener('focus', this.onVisible);
    window.addEventListener('online', this.onOnline);
    this.visit();
  }

  visible() {
    return !this.stopped && document.visibilityState === 'visible' && this.isCurrent();
  }

  visit() {
    if (!this.visible() || this.inFlight) return;
    if (!this.pending && Date.now() >= this.nextVisitAt) {
      try {
        this.pending = { id: createEventId(), attempts: 0 };
      } catch {
        this.stop(); // Analytics must not break rendering if crypto is unavailable.
        return;
      }
    }
    if (this.pending) this.send();
  }

  async send() {
    if (!this.pending || this.inFlight || !this.visible() || navigator.onLine === false) return;
    if (Date.now() < this.nextAttemptAt) {
      this.schedule(this.nextAttemptAt - Date.now());
      return;
    }
    const { csrfToken } = window;
    if (!csrfToken) {
      // The feed can render before the asynchronous CSRF bootstrap finishes.
      this.schedule(1000);
      return;
    }

    clearTimeout(this.retryTimer);
    const event = this.pending;
    event.attempts += 1;
    this.inFlight = true;
    const controller = new AbortController();
    this.controller = controller;
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT);
    let retryDelay = null;
    try {
      const response = await window.fetch('/feed_config_visits', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
        body: JSON.stringify({ visit_token: this.token, event_id: event.id }),
        signal: controller.signal,
      });
      if (this.stopped) return;
      if (response.status === 204) {
        this.stop(); // Expired, replaced, disabled, or no longer authenticated.
      } else if (response.ok) {
        const wait = Number(response.headers.get('X-Feed-Visit-Wait'));
        this.nextVisitAt = Date.now() + (Number.isFinite(wait) && wait > 0 ? wait * 1000 : 0);
        this.pending = null;
        this.nextAttemptAt = 0;
      } else if ([408, 429].includes(response.status) || response.status >= 500) {
        const after = response.headers.get('Retry-After');
        const seconds = after && Number(after);
        const delay = after && (Number.isFinite(seconds) ? seconds * 1000 : Date.parse(after) - Date.now());
        retryDelay = Number.isFinite(delay) && delay > 0 ? delay : this.backoff(event.attempts);
      } else {
        this.stop(); // Permanent failures, including an expired CSRF session.
      }
    } catch {
      if (!this.stopped) retryDelay = this.backoff(event.attempts);
    } finally {
      clearTimeout(timeout);
      this.inFlight = false;
      this.controller = null;
      if (!this.stopped && retryDelay !== null) {
        if (event.attempts >= MAX_ATTEMPTS) {
          this.pending = null;
          this.nextVisitAt = Date.now() + 300000;
        } else {
          this.nextAttemptAt = Date.now() + retryDelay;
          this.schedule(retryDelay);
        }
      }
    }
  }

  backoff(attempts) {
    return Math.max(1000, Math.random() * Math.min(60000, 1000 * 2 ** attempts));
  }

  schedule(delay) {
    clearTimeout(this.retryTimer);
    this.retryTimer = setTimeout(() => this.send(), Math.min(delay, 2147483647));
  }

  stop() {
    this.stopped = true;
    clearTimeout(this.retryTimer);
    this.controller?.abort();
    document.removeEventListener('visibilitychange', this.onVisible);
    window.removeEventListener('pageshow', this.onVisible);
    window.removeEventListener('focus', this.onVisible);
    window.removeEventListener('online', this.onOnline);
  }
}
