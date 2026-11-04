import '@testing-library/jest-dom';
import { initKeyboardShortcuts } from '../keyboardShortcuts';
import { buildUserMetadataFragment } from '../../previewCards/feedPreviewCards';
import filterXSS from '../../../assets/javascripts/lib/xss';

describe('initKeyboardShortcuts', () => {
  it('invokes matching shortcut handler and cleans up listener on teardown', () => {
    const onEscape = jest.fn();
    const cleanup = initKeyboardShortcuts({ Escape: onEscape }, document);

    document.dispatchEvent(
      new KeyboardEvent('keydown', { code: 'Escape', key: 'Escape' }),
    );
    expect(onEscape).toHaveBeenCalledTimes(1);

    cleanup();
    document.dispatchEvent(
      new KeyboardEvent('keydown', { code: 'Escape', key: 'Escape' }),
    );
    expect(onEscape).toHaveBeenCalledTimes(1);
  });

  it('ignores unmodified keystrokes inside form fields', () => {
    const onB = jest.fn();
    const input = document.createElement('input');
    input.type = 'text';
    document.body.appendChild(input);

    const cleanup = initKeyboardShortcuts({ b: onB }, document);
    input.dispatchEvent(
      new KeyboardEvent('keydown', {
        code: 'KeyB',
        key: 'b',
        bubbles: true,
      }),
    );

    expect(onB).not.toHaveBeenCalled();
    cleanup();
    input.remove();
  });
});

describe('buildUserMetadataFragment', () => {
  it('builds user metadata DOM nodes with safe textContent', () => {
    const container = document.createElement('div');
    const fragment = buildUserMetadataFragment({
      summary: 'Builder of things',
      email: 'dev@example.com',
      work: 'Engineer',
      location: 'NYC',
      education: 'CS',
      created_at: '2020-01-15T00:00:00Z',
    });
    container.appendChild(fragment);

    expect(container.querySelector('.color-base-70')).toHaveTextContent(
      'Builder of things',
    );
    expect(container.querySelector('a[href="mailto:dev@example.com"]')).toHaveTextContent(
      'dev@example.com',
    );
    expect(container.querySelector('.user-metadata-details-inner')).toHaveTextContent(
      'Engineer',
    );
    expect(container.querySelector('.user-metadata-details-inner')).toHaveTextContent(
      'NYC',
    );
    expect(container.querySelector('.user-metadata-details-inner')).toHaveTextContent(
      'CS',
    );
    expect(
      container.querySelector('time[datetime="2020-01-15T00:00:00Z"]'),
    ).not.toBeNull();
  });
});

describe('filterXSS', () => {
  it('strips HTML comments and escapes angle brackets', () => {
    expect(filterXSS('')).toBe('');
    expect(filterXSS(null)).toBe('');
    expect(filterXSS('Hello <!-- comment --><b>World</b>')).toBe(
      'Hello &lt;b&gt;World&lt;/b&gt;',
    );
    expect(filterXSS('<!<!-- comment -->-- inner -->')).toBe('');
    expect(filterXSS('<script>alert(1)</script>')).toBe(
      '&lt;script&gt;alert(1)&lt;/script&gt;',
    );
  });
});
