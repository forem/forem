// subscribeButton.test.js

import {
  initializeSubscribeButton,
  addButtonSubscribeText,
  optimisticallyUpdateButtonUI,
} from '../../subscribeButton';

describe('subscribeButton', () => {
  let button;
  // let handleSubscribeButtonClickSpy;
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
    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to top-level comments',
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

  it('should set label, mobileLabel, and pressed for config "author_comments"', () => {
    addButtonSubscribeText(button, 'author_comments');

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

    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to top-level comments',
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
      'Subscribed to top-level comments',
    );
    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  // it('should add click event listener to the button', () => {
  //   button.click();

  //   expect(handleSubscribeButtonClickSpy).toHaveBeenCalled();
  // });

  // it('should update button UI when clicked', () => {return new Promise((done) => {
  //   button.click();

  //   setTimeout(() => {
  //     expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
  //     expect(button.querySelector('span').innerText).toBe('Subscribed to comments');
  //     done();
  //   }, 0);
  // })});

  // it('should make AJAX request when clicked', () => {
  //   button.click();

  //   expect(window.fetch).toHaveBeenCalled();
  //   expect(window.fetch).toHaveBeenCalledWith('comment-subscribe', {
  //     method: 'POST',
  //     body: JSON.stringify({
  //       comment: {
  //         notification_id: null,
  //         comment_id: null,
  //         article_id: null
  //       }
  //     })
  //   });
  // });

  // it('should handle successful response', () => {return new Promise((done) => {
  //   const response = {
  //     status: 200,
  //     json: () => Promise.resolve({
  //       notification: '{"config":"all_comments"}'
  //     })
  //   };

  //   jest.spyOn(window, 'alert');

  //   window.fetch.and.returnValue(Promise.resolve(response));
  //   button.click();

  //   setTimeout(() => {
  //     expect(button.dataset.info).toBe('{"config":"all_comments"}');
  //     // expect(window.alert).toHaveBeenCalledWith('Subscription updated successfully!');
  //     done();
  //   }, 0);
  // })});
});
