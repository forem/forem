// subscribeButton.test.js

import {
  initializeSubscribeButton,
  addButtonSubscribeText,
  optimisticallyUpdateButtonUI,
} from '../../subscribeButton';

describe('subscribeButton', () => {
  let button;
  let originalFetch;
  const mockDatasetComment = (comment) => {
    button.dataset.comment = comment;
  };

  beforeEach(() => {
    button = document.createElement('button');
    button.classList.add('subscribe-button');
    document.body.appendChild(button);
    const spanElement = document.createElement('span');
    spanElement.textContent = 'Subscribe to comments';
    button.appendChild(spanElement);
    button.setAttribute(
      'data-info',
      '{"id":164,"user_id":11,"notifiable_id":32,"notifiable_type":"Article","config":"all_comments","created_at":"2023-06-09T05:07:47.272Z","updated_at":"2023-06-09T05:07:47.272Z"}',
    );

    // Store the original fetch function
    originalFetch = global.fetch;

    // Mock the fetch function with a spy
    global.fetch = jest.fn().mockImplementation(() => Promise.resolve({}));

    initializeSubscribeButton();
  });

  afterEach(() => {
    document.body.removeChild(button);

    // Restore the original fetch function
    global.fetch = originalFetch;
  });

  it('should initialize subscribe buttons', () => {
    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
  });

  it('should set label, mobileLabel, and pressed for config "all_comments"', () => {
    button.setAttribute('data-ancestry', null);
    addButtonSubscribeText(button, 'all_comments');

    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('should set label, mobileLabel, and pressed for config "top_level_comments"', () => {
    button.setAttribute('data-ancestry', null);
    addButtonSubscribeText(button, 'top_level_comments');

    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('should set label, mobileLabel, and pressed for config "only_author_comments"', () => {
    addButtonSubscribeText(button, 'only_author_comments');

    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to author comments',
    );
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to author comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('should set label, mobileLabel, and pressed for default config', () => {
    addButtonSubscribeText(button, 'unknown_config');

    expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to comments',
    );
    expect(button.hasAttribute('aria-pressed')).toBe(true);
  });

  it('should capitalize the mobileLabel', () => {
    mockDatasetComment('some comment');
    addButtonSubscribeText(button, 'all_comments');

    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('should remove "comment-subscribed" class and set inner text for known configs', () => {
    optimisticallyUpdateButtonUI(button);

    expect(button.classList.contains('comment-subscribed')).toBe(false);
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to comments',
    );
  });

  it('should add "comment-subscribed" class and call addButtonSubscribeText for unknown config', () => {
    optimisticallyUpdateButtonUI(button);

    expect(button.classList.contains('comment-subscribed')).toBe(false);
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to comments',
    );
    expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });

  it('should add "comment-subscribed" class and call addButtonSubscribeText when buttonInfo is null', () => {
    delete button.dataset.info;
    optimisticallyUpdateButtonUI(button);

    expect(button.classList.contains('comment-subscribed')).toBe(true);
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });
});
