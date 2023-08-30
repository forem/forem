import { h, render } from 'preact';
import { UsernameInput } from './UsernameInput/UsernameInput';
import { UserStore } from './UserStore';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

document.ready.then(() => {
  const usernameFields = document.getElementsByClassName(
    'article_org_co_author_ids_list',
  );

  const users = new UserStore();

  for (const targetField of usernameFields) {
    if (targetField) {
      targetField.type = 'hidden';
      const exceptAuthorId =
        targetField.form.querySelector('#article_user_id').value;
      const inputId = `auto${targetField.id}`; //targetField.id;
      const fetchUrl = targetField.dataset.fetchUsers;
      const row = targetField.parentElement;

      users.fetch(fetchUrl, { except: exceptAuthorId }).then(() => {
        const value = users.matchingIds(targetField.value.split(','));
        const fetchSuggestions = function (term) {
          return users.search(term);
        };

        const handleSelectionsChanged = function (ids) {
          // console.log("IDs!", ids, row, `input[id=${inputId}]`, input)
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
});
