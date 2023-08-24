/* eslint-disable no-restricted-globals */
import fetch from 'jest-fetch-mock';
import { fireEvent } from '@testing-library/preact';
import {
  addCloseListener,
  initializeHeight,
  addReactionButtonListeners,
  handleAddTagButtonListeners,
  handleAddModTagButtonsListeners,
  handleRemoveTagButtonsListeners,
} from '../actionsPanel';

global.fetch = fetch;
global.top.addSnackbarItem = jest.fn();
global.alert = jest.fn();

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
      fetch.resetMocks();

      document.body.innerHTML = `
      <button id="add-tag-button" class="add-tag" type="button">
        Add new tag
      </button>
      <div id="add-tag-container" class="hidden">
        <div id="add-reason-container" class="reason-container">
          <input id="admin-add-tag" class="crayons-textfield" type="text" autocomplete="off" placeholder="Add a tag" data-article-id="32" data-adjustment-type="plus">
          <textarea class="crayons-textfield" placeholder="Reason to add tag (optional)" id="tag-add-reason"></textarea>
          <div class="flex gap-3">
            <button class="w-100 c-btn c-btn--primary" disabled="disabled" id="tag-add-submit">Submit</button>
            <button class="w-100 c-btn" id="cancel-add-tag-button" type="button">Cancel</button>
          </div>
        </div>
      </div>
      `;

      handleAddTagButtonListeners();
    });

    function tagResponse() {
      return JSON.stringify({
        status: 'Success',
        result: 'addition',
        colors: {
          bg: '#8c5595',
          text: '#39ad55',
        },
      });
    }

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

    it('by default the add tag submit button is disabled and gets enabled when entered tag', () => {
      document.getElementById('add-tag-button').click();
      expect(
        document.getElementById('tag-add-submit').hasAttribute('disabled'),
      ).toBeTruthy();

      fireEvent.input(document.getElementById('admin-add-tag'), {
        target: { value: 'New Tag' },
      });

      expect(
        document.getElementById('tag-add-submit').hasAttribute('disabled'),
      ).toBeFalsy();
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

    it('click on add-tag button hides the container and shows add-tag button', async () => {
      fetch.mockResponseOnce(tagResponse());

      const addTagButton = document.getElementById('add-tag-button');

      addTagButton.click();

      fireEvent.input(document.getElementById('admin-add-tag'), {
        target: { value: 'New Tag' },
      });
      expect(
        document.getElementById('tag-add-submit').hasAttribute('disabled'),
      ).toBeFalsy();

      document.getElementById('tag-add-reason').value = 'Adding a new tag';
      document.getElementById('tag-add-submit').click();

      expect(fetch).toHaveBeenCalledTimes(1);
    });

    it('shows the adjustment container when admin input is focused', () => {
      document.getElementById('add-tag-button').click();
      document.getElementById('admin-add-tag').value = 'pizza';
      document.getElementById('tag-add-reason').value = 'Adding a new tag';
      document.getElementById('tag-add-submit').click();

      expect(
        document.getElementById('add-reason-container').classList,
      ).not.toContain('hidden');
    });
  });

  describe('article has 1 tag', () => {
    const discussTag = 'discuss';

    function removeTagResponse() {
      return JSON.stringify({
        status: 'Success',
        result: 'removal',
        colors: {
          bg: '#8c5595',
          text: '#39ad55',
        },
      });
    }

    beforeEach(() => {
      fetch.resetMocks();

      document.body.innerHTML = `
      <button id="remove-tag-button-${discussTag}" class="adjustable-tag" type="button" data-adjustment-type="subtract" data-tag-name="${discussTag}" data-article-id="32">
        <span class="num-sign">#</span>${discussTag}
        <div id="remove-tag-icon-${discussTag}" class="circle centered-icon adjustment-icon subtract color-base-inverted hidden">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" role="img"><title id="random">Remove tag</title>
            <path d="M19 11H5v2h14v-2Z"></path>
          </svg>
        </div>
      </button>
      <div id="remove-tag-container-${discussTag}" class="hidden">
        <div id="adjustment-reason-container-${discussTag}" class="reason-container">
          <textarea class="crayons-textfield" placeholder="Reason to remove tag (optional)" id="tag-removal-reason-${discussTag}"></textarea>
          <div class="flex gap-3">
            <button class="crayons-btn" id="remove-tag-submit-${discussTag}">Submit</button>
            <button class="c-btn" id="cancel-remove-tag-button-${discussTag}" type="button">Cancel</button>
          </div>
        </div>
      </div>
      `;

      handleRemoveTagButtonsListeners();
    });

    it('remove tag container is hidden', () => {
      expect(
        document.getElementById(`remove-tag-container-${discussTag}`).classList,
      ).toContain('hidden');
    });

    it('hides remove icon on button click', () => {
      document.getElementById(`remove-tag-button-${discussTag}`).click();

      expect(
        document.getElementById(`remove-tag-icon-${discussTag}`).style.display,
      ).toEqual('none');
    });

    it('shows tag container on button click', () => {
      document.getElementById(`remove-tag-button-${discussTag}`).click();

      expect(
        document.getElementById(`remove-tag-container-${discussTag}`).classList,
      ).not.toContain('hidden');
    });

    it('click on cancel button hides the container', () => {
      document.getElementById(`remove-tag-button-${discussTag}`).click();
      document.getElementById(`cancel-remove-tag-button-${discussTag}`).click();

      expect(
        document.getElementById(`remove-tag-container-${discussTag}`).classList,
      ).toContain('hidden');
    });

    it('click on remove button should successfully remove the item', async () => {
      fetch.mockResponseOnce(removeTagResponse());

      document.getElementById(`remove-tag-button-${discussTag}`).click();
      document.getElementById(`tag-removal-reason-${discussTag}`).value =
        'Removing a tag';
      document.getElementById(`remove-tag-submit-${discussTag}`).click();

      expect(fetch).toHaveBeenCalledTimes(1);
    });
  });

  describe('tag moderator role', () => {
    const discussTag = 'discuss';

    function addModTagResponse() {
      return JSON.stringify({
        status: 'Success',
        result: 'addition',
        colors: {
          bg: '#8c5595',
          text: '#39ad55',
        },
      });
    }

    beforeEach(() => {
      fetch.resetMocks();

      document.body.innerHTML = `
      <button
        id="add-tag-button-${discussTag}"
        class="adjustable-tag add-tag" type="button"
        data-adjustment-type="plus"
        data-tag-name="${discussTag}"
        data-article-id="<%= @moderatable.id %>">
        <span class="num-sign">#</span>${discussTag}
        <div id="add-tag-icon-${discussTag}" class="circle centered-icon add-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" role="img"><title id="random">Remove tag</title>
            <path d="M19 11H5v2h14v-2Z"></path>
          </svg>
        </div>
      </button>
      <div id="add-tag-container-${discussTag}" class="hidden">
        <div id="add-reason-container-${discussTag}" class="reason-container">
          <textarea id="tag-add-reason-${discussTag}" class="crayons-textfield mt-3" placeholder="<%= t("views.moderations.actions.adjust.reason.add_tag") %>"></textarea>
          <div class="flex gap-3">
            <button class="w-100 c-btn c-btn--primary" id="tag-add-submit-${discussTag}"><%= t("views.moderations.actions.adjust.add") %></button>
            <button class="w-100 c-btn" id="cancel-add-tag-button-${discussTag}" type="button"><%= t("views.moderations.actions.adjust.cancel") %></button>
          </div>
        </div>
      </div>
      `;

      handleAddModTagButtonsListeners();
    });

    it('add moderator tag container is hidden', () => {
      expect(
        document.getElementById(`add-tag-container-${discussTag}`).classList,
      ).toContain('hidden');
    });

    it('hides add icon on button click', () => {
      document.getElementById(`add-tag-button-${discussTag}`).click();

      expect(
        document.getElementById(`add-tag-icon-${discussTag}`).style.display,
      ).toEqual('none');
    });

    it('shows tag container on button click', () => {
      document.getElementById(`add-tag-button-${discussTag}`).click();

      expect(
        document.getElementById(`add-tag-container-${discussTag}`).classList,
      ).not.toContain('hidden');
    });

    it('click on cancel button hides the container', () => {
      document.getElementById(`add-tag-button-${discussTag}`).click();
      document.getElementById(`cancel-add-tag-button-${discussTag}`).click();

      expect(
        document.getElementById(`add-tag-container-${discussTag}`).classList,
      ).toContain('hidden');
    });

    it('click on add button should successfully add the item', async () => {
      fetch.mockResponseOnce(addModTagResponse());

      document.getElementById(`add-tag-button-${discussTag}`).click();
      document.getElementById(`tag-add-reason-${discussTag}`).value =
        'Add a tag';
      document.getElementById(`tag-add-submit-${discussTag}`).click();

      expect(fetch).toHaveBeenCalledTimes(1);
    });
  });
});

/* eslint-enable no-restricted-globals */
