import { h, render } from 'preact';
import { UsernameInput } from '../../shared/components/UsernameInput';
import { UserStore } from '../../shared/components/UserStore';
import '@utilities/document_ready';

async function convertUserIdFieldToUsernameField(targetField, users, fetchUrl) {
  targetField.type = 'hidden';

  const inputId = `auto${targetField.id}`;
  const newDiv = document.createElement('div');
  targetField.parentElement.append(newDiv);

  await users.fetch(fetchUrl).then(() => {
    const value = users.matchingIds(targetField.value.split(','));

    const fetchSuggestions = function (term) {
      return users.search(term);
    };

    const handleSelectionsChanged = function (ids) {
      targetField.value = ids;
    };

    render(
      <UsernameInput
        labelText="Enter a username"
        placeholder="Enter a username"
        maxSelections={1}
        inputId={inputId}
        defaultValue={value}
        fetchSuggestions={fetchSuggestions}
        handleSelectionsChanged={handleSelectionsChanged}
      />,
      newDiv,
    );
  });
}

async function convertCoAuthorIdsToUsernameInputs(
  targetField,
  users,
  fetchUrl,
) {
  targetField.type = 'hidden';

  const exceptAuthorId = targetField.form.querySelector(
    'input[name="article[user_id]"]',
  )?.value;

  let searchOptions = {};
  if (exceptAuthorId) {
    searchOptions = { except: exceptAuthorId };
  }

  const inputId = `auto${targetField.id}`;
  const newDiv = document.createElement('div');
  targetField.parentElement.append(newDiv);

  await users.fetch(fetchUrl).then(() => {
    const value = users.matchingIds(targetField.value.split(','));

    const fetchSuggestions = function (term) {
      return users.search(term, searchOptions);
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
      newDiv,
    );
  });
}

export async function convertCoauthorIdsToUsernameInputs() {
  const users = new UserStore();
  const fetchUrl = '/admin/member_manager/users.json';

  const usernameFields = document.getElementsByClassName(
    'js-username_id_input',
  );

  for (const targetField of usernameFields) {
    convertUserIdFieldToUsernameField(targetField, users, fetchUrl);
  }

  const coAuthorFields = document.getElementsByClassName(
    'js-coauthor_username_id_input',
  );

  for (const coAuthorField of coAuthorFields) {
    convertCoAuthorIdsToUsernameInputs(coAuthorField, users, fetchUrl);
  }
}

document.ready.then(() => {
  convertCoauthorIdsToUsernameInputs();
});
