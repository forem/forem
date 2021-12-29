/* eslint-disable no-restricted-globals */
import fetch from 'jest-fetch-mock';
import {
  addCloseListener,
  initializeHeight,
  addReactionButtonListeners,
  addAdjustTagListeners,
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
  describe('when the user is tag moderator of #discuss', () => {
    beforeEach(() => {
      const tagName = 'discuss';
      document.body.innerHTML = `
      <a href="/t/${tagName}" class="tag">${tagName}</a>
      <button class="adjustable-tag" data-adjustment-type="subtract" data-tag-name="${tagName}">
        #${tagName}
      </button>
      <form id="adjustment-reason-container" class="adjustment-reason-container hidden">
        <textarea class="crayons-textfield" placeholder="Reason for tag adjustment (required)" id="tag-adjustment-reason" required></textarea>
        <button class="crayons-btn" id="tag-adjust-submit" type="submit">Submit</button>
      </form>
    `;

      addAdjustTagListeners();
    });
    describe('when an article is tagged with #discuss', () => {
      it('toggles the tag button and the form', () => {
        const tagBtn = document.getElementsByClassName('adjustable-tag')[0];
        tagBtn.click();
        expect(tagBtn.classList).toContain('active');
        expect(
          document.getElementById('adjustment-reason-container').classList,
        ).not.toContain('hidden');
      });
      it('hides the form if the button is clicked again', () => {
        const tagBtn = document.getElementsByClassName('adjustable-tag')[0];
        tagBtn.click();
        tagBtn.click();
        expect(
          document.getElementById('adjustment-reason-container').classList,
        ).toContain('hidden');
      });
    });
  });

  describe('when the user is an admin and the article has room for tags', () => {
    describe('tag adjustment interactions', () => {
      beforeEach(() => {
        const tagName = 'discuss';
        document.body.innerHTML = `
          <div class="add-tag-container">
            <input id="admin-add-tag" class="crayons-textfield" type="text" placeholder="Add a tag" data-article-id="1" data-adjustment-type="plus">
          </div>
          <a href="/t/${tagName}" class="tag">${tagName}</a>
          <button class="adjustable-tag" data-adjustment-type="subtract" data-tag-name="${tagName}">
            #${tagName}
          </button>
          <button class="adjustable-tag" data-adjustment-type="subtract" data-tag-name="ruby">
            #ruby
          </button>
          <form id="adjustment-reason-container" class="adjustment-reason-container hidden">
            <textarea class="crayons-textfield" placeholder="Reason for tag adjustment" id="tag-adjustment-reason" required></textarea>
            <button class="crayons-btn" id="tag-adjust-submit" type="submit">Submit</button>
          </form>
        `;
        addAdjustTagListeners();
      });
      it('shows the adjustment container when admin input is focused', () => {
        document.getElementById('admin-add-tag').focus();
        expect(
          document.getElementById('adjustment-reason-container').classList,
        ).not.toContain('hidden');
      });
      it('triggers a confirmation if the admin add tag input was filled in', () => {
        window.confirm = jest.fn();
        document.getElementById('admin-add-tag').value = 'pizza';
        document.querySelector('.adjustable-tag[data-tag-name="ruby"]').click();
        expect(window.confirm).toHaveBeenCalled();
      });
      it('does not the hide reason container when going from one tag to another tag', () => {
        document.getElementsByClassName('adjustable-tag')[0].click();
        document.querySelector('.adjustable-tag[data-tag-name="ruby"]').click();
        expect(
          document.getElementById('adjustment-reason-container').classList,
        ).not.toContain('hidden');
      });
    });
  });
});

/* eslint-enable no-restricted-globals */
