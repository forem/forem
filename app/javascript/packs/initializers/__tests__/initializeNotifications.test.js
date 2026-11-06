import { initializeNotifications } from '../initializeNotifications';

// The initializer imports a handful of collaborators that reach out to the
// network / render UI. Stub them so the tests stay focused on the reply-form
// toggle behaviour.
jest.mock('../../../utilities/checkUserLoggedIn', () => ({
  checkUserLoggedIn: jest.fn(() => true),
}));
jest.mock('../../../utilities/showUserAlertModal', () => ({
  showModalAfterError: jest.fn(),
}));
jest.mock('../../subscribeButton', () => ({
  initializeSubscribeButton: jest.fn(),
}));

/**
 * Builds the DOM for a single comment notification with a (hidden) inline
 * reply form, mirroring app/views/notifications/shared/_comment_box.html.erb.
 *
 * @param {number} commentId
 * @returns {string} HTML markup
 */
function notificationMarkup(commentId) {
  return `
    <div class="crayons-card notification__preview relative">
      <footer class="comment-actions">
        <div class="notification__actions">
          <button
            class="crayons-btn toggle-reply-form inline-flex"
            data-reactable-id="${commentId}"
            aria-label="Reply"></button>
        </div>
        <form id="comment-form-for-${commentId}" class="comment-form hidden">
          <div class="comment-form__inner">
            <div class="comment-form__field">
              <textarea
                id="comment-textarea-for-${commentId}"
                class="comment-textarea crayons-textfield crayons-textfield--ghost"
                placeholder="Reply..."></textarea>
            </div>
            <div class="comment-form__buttons mb-4 flex items-center">
              <button type="submit">Submit</button>
              <button
                type="button"
                class="js-notification-reply-dismiss"
                data-reactable-id="${commentId}">Dismiss</button>
            </div>
          </div>
        </form>
      </footer>
    </div>
  `;
}

describe('initializeNotifications reply form toggle', () => {
  let initializeEnhancedCommentTextArea;

  beforeEach(() => {
    jest.useFakeTimers();

    document.body.setAttribute('data-user-status', 'logged-in');
    document.body.innerHTML = `
      <div id="notifications-container">
        <div id="articles-list">
          ${notificationMarkup(31)}
        </div>
      </div>
    `;

    // Collaborators invoked by unrelated branches of the initializer.
    global.getCsrfToken = jest.fn(() => Promise.resolve('csrf'));
    global.sendFetch = jest.fn(() => jest.fn());
    global.instantClick = undefined;
    global.InstantClick = { removeExpiredKeys: jest.fn(), preload: jest.fn() };

    // Mounting helper that commentsPage normally registers on window.Forem.
    initializeEnhancedCommentTextArea = jest.fn();
    window.Forem = { initializeEnhancedCommentTextArea };

    // Keep markNotificationsAsRead's fetch from throwing.
    global.fetch = jest.fn(() => Promise.resolve({ status: 200 }));
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'jest',
      configurable: true,
    });
  });

  afterEach(() => {
    jest.clearAllTimers();
    jest.useRealTimers();
    delete window.Forem;
    delete global.getCsrfToken;
    delete global.sendFetch;
    delete global.InstantClick;
    delete global.instantClick;
    document.body.removeAttribute('data-user-status');
  });

  const openReplyForm = () => {
    initializeNotifications();
    // initReactions wires up handlers inside a 180ms timeout.
    jest.advanceTimersByTime(180);
    document.querySelector('.toggle-reply-form').click();
    // The textarea focus + toolbar mount happen inside a nested 30ms timeout.
    jest.advanceTimersByTime(30);
  };

  it('reveals the hidden reply form and hides the toggle button when "Reply" is clicked', () => {
    openReplyForm();

    const form = document.getElementById('comment-form-for-31');
    const toggle = document.querySelector('.toggle-reply-form');

    expect(form.classList.contains('hidden')).toBe(false);
    expect(toggle.classList.contains('hidden')).toBe(true);
    expect(toggle.classList.contains('inline-flex')).toBe(false);
  });

  it('mounts the enhanced comment textarea (toolbar) on the revealed reply form', () => {
    openReplyForm();

    const textarea = document.getElementById('comment-textarea-for-31');
    expect(initializeEnhancedCommentTextArea).toHaveBeenCalledTimes(1);
    expect(initializeEnhancedCommentTextArea).toHaveBeenCalledWith(textarea);
  });

  it('does not throw when the enhancement helper is unavailable', () => {
    window.Forem = {};

    expect(() => openReplyForm()).not.toThrow();

    // Form is still revealed even though the toolbar could not be mounted.
    expect(
      document.getElementById('comment-form-for-31').classList.contains('hidden'),
    ).toBe(false);
  });

  it('re-hides the reply form and restores the toggle button on dismiss', () => {
    openReplyForm();

    document.querySelector('.js-notification-reply-dismiss').click();

    const form = document.getElementById('comment-form-for-31');
    const toggle = document.querySelector('.toggle-reply-form');

    expect(form.classList.contains('hidden')).toBe(true);
    expect(toggle.classList.contains('hidden')).toBe(false);
    expect(toggle.classList.contains('inline-flex')).toBe(true);
  });
});
