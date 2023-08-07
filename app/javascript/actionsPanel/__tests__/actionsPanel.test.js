/* eslint-disable no-restricted-globals */
import fetch from 'jest-fetch-mock';
import {
  addCloseListener,
  initializeHeight,
  addReactionButtonListeners,
  handleAddTagButtonListeners,
} from '../actionsPanel';

describe('addCloseListener()', () => {
  test('toggles the mod actions panel and its button on click', () => {
    document.body.innerHTML = `
    <body>
      <div class="mod-actions-menu showing">
        <button class="close-actions-panel circle centered-icon" type="button" title="Close moderator actions panel">
        </button>
      </div>
      <div id="mod-actions-menu-btn-area">
        <div class="mod-actions-menu-btn crayons-btn crayons-btn--icon-rounded crayons-btn--s">
        </div>
      </div>
    </body>
    `;
    addCloseListener();

    const closeButton = document.getElementsByClassName(
      'close-actions-panel',
    )[0];
    closeButton.click();
    // eslint-disable-next-line no-restricted-globals
    const modPanel = top.document.getElementsByClassName('mod-actions-menu')[0];
    expect(modPanel.classList).not.toContain('showing');
  });
});

describe('initializeHeight()', () => {
  test('it sets the height of the proper elements', () => {
    document.body.innerHTML = `
    <body>
      <div id="page-content">
        <div id="page-content-inner">
        </div>
      </div>
    </body>
    `;
    initializeHeight();

    const { body } = document;
    expect(document.documentElement.style.height).toEqual('100%');
    expect(body.style.height).toEqual('100%');
    expect(body.style.margin).toEqual('0px');
    expect(body.style.marginTop).toEqual('0px');
    expect(body.style.marginBottom).toEqual('0px');
    expect(body.style.paddingTop).toEqual('0px');
    expect(body.style.paddingTop).toEqual('0px');
  });
});

describe('addReactionButtonListeners()', () => {
  beforeEach(() => {
    fetch.resetMocks();

    document.body.innerHTML = `
    <button class="reaction-button" data-reactable-id="1" data-reactable-type="Article" data-category="thumbsup">
    </button>
    <button class="reaction-button" data-reactable-id="1" data-reactable-type="Article" data-category="thumbsdown">
    </button>
    <button class="reaction-vomit-button" data-reactable-id="1" data-reactable-type="Article" data-category="vomit">
    </button>
    `;

    const csrfToken = 'this-is-a-csrf-token';

    window.fetch = fetch;
    window.getCsrfToken = async () => csrfToken;
    top.addSnackbarItem = jest.fn();
  });

  function sampleResponse(category, create = true) {
    return JSON.stringify({
      outcome: {
        result: create ? 'create' : 'destroy',
        category,
      },
    });
  }

  describe('when no reactions are already reacted on', () => {
    test('it marks thumbs up reaction as reacted', async () => {
      let category = 'thumbsup';
      fetch.mockResponse(sampleResponse(category));
      addReactionButtonListeners();

      const thumbsupButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsupButton.click();
      expect(thumbsupButton.classList).toContain('reacted');

      category = 'thumbsdown';
      const thumbsdownButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsdownButton.click();
      expect(thumbsdownButton.classList).toContain('reacted');

      category = 'vomit';
      fetch.resetMocks();
      fetch.mockResponse(sampleResponse(category));
      const vomitButton = document.querySelector(
        `.reaction-vomit-button[data-category="${category}"]`,
      );
      vomitButton.click();
      expect(vomitButton.classList).toContain('reacted');
    });
    test('it unmarks the proper reaction(s) when positive/negative reactions are clicked', async () => {
      let category = 'thumbsup';
      fetch.mockResponse(sampleResponse(category));
      addReactionButtonListeners();
      const thumbsupButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsupButton.click();

      category = 'thumbsdown';
      fetch.resetMocks();
      fetch.mockResponse(sampleResponse(category));
      const thumbsdownButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsdownButton.click();
      expect(thumbsupButton.classList).not.toContain('reacted');

      fetch.resetMocks();
      category = 'thumbsup';
      fetch.mockResponse(sampleResponse(category, false));
      thumbsupButton.click();
      expect(thumbsdownButton.classList).not.toContain('reacted');
      expect(thumbsupButton.classList).toContain('reacted');

      category = 'vomit';
      fetch.resetMocks();
      fetch.mockResponse(sampleResponse(category));
      const vomitButton = document.querySelector(
        `.reaction-vomit-button[data-category="${category}"]`,
      );
      vomitButton.click();
      expect(vomitButton.classList).toContain('reacted');
      expect(thumbsupButton.classList).not.toContain('reacted');
    });
  });
});

describe('addAdjustTagListeners()', () => {
  describe('when an article has no tags', () => {
    beforeEach(() => {
      document.body.innerHTML = `
      <button id="add-tag-button" class="add-tag" type="button">
        Add new tag
      </button>
      <div id="add-tag-container" class="hidden">
        <form id="add-reason-container" class="reason-container">
          <input id="admin-add-tag" class="crayons-textfield" type="text" autocomplete="off" placeholder="Add a tag" data-article-id="32" data-adjustment-type="plus">
          <textarea class="crayons-textfield" placeholder="Reason to add tag (optional)" id="tag-add-reason"></textarea>
          <div class="flex gap-3">
            <button class="c-btn c-btn--primary" id="tag-add-submit" type="submit">Submit</button>
            <button class="c-btn" id="cancel-add-tag-button" type="button">Cancel</button>
          </div>
        </form>
      </div>
      `;
      handleAddTagButtonListeners();
    });

    it('shows the add tag button', () => {
      expect(document.getElementById('add-tag-button').classList).not.toContain(
        'hidden',
      );

      expect(document.getElementById('add-tag-container').classList).toContain(
        'hidden',
      );
    });

    it('click on add tag button shows the container and hides the button', () => {
      document.getElementById('add-tag-button').click();
      expect(document.getElementById('add-tag-button').classList).toContain(
        'hidden',
      );

      expect(
        document.getElementById('add-tag-container').classList,
      ).not.toContain('hidden');
    });

    it('click on cancel button hides the container and shows add-tag button', () => {
      document.getElementById('add-tag-button').click();
      document.getElementById('cancel-add-tag-button').click();
      expect(document.getElementById('add-tag-button').classList).not.toContain(
        'hidden',
      );

      expect(document.getElementById('add-tag-container').classList).toContain(
        'hidden',
      );
    });

    // it('click on add-tag button hides the container and shows add-tag button', () => {
    //   document.getElementById('add-tag-button').click();
    //   document.getElementById('admin-add-tag').value = 'pizza';
    //   document.getElementById('tag-add-reason').value = 'Adding a new tag';
    //   document.getElementById('tag-add-submit').click();

    //   expect(document.getElementById('add-tag-button').classList).not.toContain('hidden');

    //   expect(document.getElementById('add-tag-container').classList).toContain('hidden');
    // });
  });
});

/* eslint-enable no-restricted-globals */
