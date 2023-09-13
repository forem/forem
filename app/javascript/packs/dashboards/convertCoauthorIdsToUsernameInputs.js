import { h, render } from 'preact';
import { UsernameInput } from '../../shared/components/UsernameInput';
import { UserStore } from '../../shared/components/UserStore';
import '@utilities/document_ready';

export async function convertCoauthorIdsToUsernameInputs() {
  const usernameFields = document.getElementsByClassName(
    'article_org_co_author_ids_list',
  );

  const users = new UserStore();

  for (const targetField of usernameFields) {
    targetField.type = 'hidden';
    const exceptAuthorId =
      targetField.form.querySelector('#article_user_id').value;
    const inputId = `auto${targetField.id}`;
    const fetchUrl = targetField.dataset.fetchUsers;
    const row = targetField.parentElement;

    await users.fetch(fetchUrl).then(() => {
      const value = users.matchingIds(targetField.value.split(','));
      const fetchSuggestions = function (term) {
        return users.search(term, { except: exceptAuthorId });
      };

      const handleSelectionsChanged = function (ids) {
        targetField.value = ids;
      };

      render(
        <UsernameInput
          labelText="Add up to 4"
          placeholder="Add up to 4..."
          maxSelections={4}
          inputId={inputId}
          defaultValue={value}
          fetchSuggestions={fetchSuggestions}
          handleSelectionsChanged={handleSelectionsChanged}
        />,
        row,
      );
    });
  }
}

document.ready.then(() => {
  convertCoauthorIdsToUsernameInputs();
});
