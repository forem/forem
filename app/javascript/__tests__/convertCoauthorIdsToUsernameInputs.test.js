import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { userEvent } from '@testing-library/user-event';

import { convertCoauthorIdsToUsernameInputs } from '../packs/dashboards/convertCoauthorIdsToUsernameInputs';

global.fetch = fetch;

function fakeFetchResponseJSON() {
  return JSON.stringify([
    { name: 'Alice', username: 'alice', id: 1 },
    { name: 'Bob', username: 'bob', id: 2 },
    { name: 'Charlie', username: 'charlie', id: 3 },
  ]);
}

describe('convertCoauthorIdsToUsernameInputs', () => {
  beforeEach(() => {
    global.Honeybadger = { notify: jest.fn() };

    fetch.resetMocks();
    fetch.mockResponse(fakeFetchResponseJSON());
  });

  describe('when there is no pre-existing id value', () => {
    beforeEach(() => {
      window.document.body.innerHTML = `
      <form method="post">
        <div class="crayons-field mb-4">
          <label for="user_id">Author</label>
          <select class="crayons-select" name="article[user_id]" id="article_user_id">
            <option selected="selected" value="1">
              Alice
            </option>
            <option value="2">
              Bob
            </option>
            <option value="3">
              Charlie
            </option>
          </select>
        </div>

        <div class="crayons-field mb-4">
          <label for="co_author_ids">Co-authors</label>
          <div class="crayons-field">
            <input id="article_ID_co_author_ids_list"
                   class="article_org_co_author_ids_list"
                   name="article[co_author_ids_list]"
                   data-fetch-users="/org7053/members.json"
                   type="text"
                   value="" >
          </div>
        </div>

        <button type="submit" class="crayons-btn">Save</button>
      </form>
      `;
    });

    it('calls fetch, with exception for author ID', async () => {
      await convertCoauthorIdsToUsernameInputs();
      expect(fetch).toHaveBeenCalledWith('/org7053/members.json');
    });

    it('makes the co-author field hidden', async () => {
      await convertCoauthorIdsToUsernameInputs();
      const co_author_field = document.getElementById(
        'article_ID_co_author_ids_list',
      );
      expect(co_author_field.type).toBe('hidden');
    });

    it('renders matching snapshot', async () => {
      await convertCoauthorIdsToUsernameInputs();
      expect(document.forms[0].innerHTML).toMatchSnapshot();
    });

    it('works as expected', async () => {
      await convertCoauthorIdsToUsernameInputs();
      const input = document.querySelector(
        "input[placeholder='Add up to 4...']",
      );
      input.focus();
      await userEvent.type(input, 'Bob,');

      const hiddenField = document.querySelector(
        "input[name='article[co_author_ids_list]']",
      );
      expect(hiddenField.value).toBe('2');
    });
  });

  describe('when there *is* a pre-existing id value', () => {
    beforeEach(() => {
      window.document.body.innerHTML = `
      <form method="post">
        <div class="crayons-field mb-4">
          <label for="user_id">Author</label>
          <select class="crayons-select" name="article[user_id]" id="article_user_id">
            <option selected="selected" value="1">
              Alice
            </option>
            <option value="2">
              Bob
            </option>
            <option value="3">
              Charlie
            </option>
          </select>
        </div>

        <div class="crayons-field mb-4">
          <label for="co_author_ids">Co-authors</label>
          <div class="crayons-field">
            <input id="article_ID_co_author_ids_list"
                   class="article_org_co_author_ids_list"
                   name="article[co_author_ids_list]"
                   data-fetch-users="/org7053/members.json"
                   type="text"
                   value="3" >
          </div>
        </div>

        <button type="submit" class="crayons-btn">Save</button>
      </form>
      `;
    });

    it('renders matching snapshot', async () => {
      await convertCoauthorIdsToUsernameInputs();
      expect(document.forms[0].innerHTML).toMatchSnapshot();
    });

    it('works as expected', async () => {
      await convertCoauthorIdsToUsernameInputs();
      const input = document.querySelector(
        "input[placeholder='Add another...']",
      );
      input.focus();
      await userEvent.type(input, 'Bob,');

      const hiddenField = document.querySelector(
        "input[name='article[co_author_ids_list]']",
      );
      expect(hiddenField.value).toBe('3, 2');
    });

    it('can remove previously selected', async () => {
      await convertCoauthorIdsToUsernameInputs();
      const deselect = document.querySelector(
        '.c-autocomplete--multi__selected',
      );
      await userEvent.click(deselect);

      const hiddenField = document.querySelector(
        "input[name='article[co_author_ids_list]']",
      );
      expect(hiddenField.value).toBe('');
    });
  });
});
