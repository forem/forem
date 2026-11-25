import { buildHTML } from '../responseTemplates/responseTemplates';

describe('buildHTML', () => {
  it('escapes HTML characters in personal_comment templates while preserving insertable text', () => {
    const html = buildHTML(
      [
        {
          id: 1,
          title: 'Use <code>& "quotes"</code>',
          content: "Snippet with <tag attr=\"a\" 'b'> & text",
        },
      ],
      'personal_comment',
    );

    const container = document.createElement('div');
    container.innerHTML = html;

    expect(container.querySelector('code')).toBeNull();
    expect(container.querySelector('tag')).toBeNull();
    expect(container.querySelector('h4').textContent).toBe(
      'Use <code>& "quotes"</code>',
    );
    expect(container.querySelector('p').textContent).toBe(
      "Snippet with <tag attr=\"a\" 'b'> & text",
    );
    expect(container.querySelector('.insert-template-button').dataset.content).toBe(
      "Snippet with <tag attr=\"a\" 'b'> & text",
    );
  });

  it('escapes HTML characters in mod_comment templates while preserving insertable text', () => {
    const html = buildHTML(
      [
        {
          id: 42,
          title: '<b>Notice</b> & reminder',
          content: 'Please avoid <img src="x"> & review guidelines',
        },
      ],
      'mod_comment',
    );

    const container = document.createElement('div');
    container.innerHTML = html;

    expect(container.querySelector('b')).toBeNull();
    expect(container.querySelector('img')).toBeNull();
    expect(container.querySelector('h4').textContent).toBe(
      '<b>Notice</b> & reminder',
    );
    expect(container.querySelector('p').textContent).toBe(
      'Please avoid <img src="x"> & review guidelines',
    );
    expect(
      container.querySelector('.moderator-submit-button').dataset
        .responseTemplateId,
    ).toBe('42');
    expect(container.querySelector('.insert-template-button').dataset.content).toBe(
      'Please avoid <img src="x"> & review guidelines',
    );
  });

  it('returns the empty state markup when personal_comment list is empty', () => {
    const html = buildHTML([], 'personal_comment');

    expect(html).toContain('mod-response-wrapper-empty');
  });
});
