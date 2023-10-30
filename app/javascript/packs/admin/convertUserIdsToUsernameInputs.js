import { h, render } from 'preact';
import { UsernameInput } from '@components/UsernameInput';
import { UserStore } from '@components/UserStore';
import '@utilities/document_ready';

const CO_AUTHOR_FIELD_CLASS_NAME = '.js-coauthor_username_id_input';
const USERNAME_FIELD_CLASS_NAME = '.js-username_id_input';

function generateFetchUrl(ids) {
  const searchParams = new URLSearchParams();
  ids.forEach((id) => searchParams.append('ids[]', Number(id)));
  return `/admin/member_manager/users.json?${searchParams}'`;
}

function extractUserIds(value) {
  return value
    .split(',')
    .map((id) => id.replace(' ', ''))
    .filter((id) => id !== '');
}

function getAllUserIdsFromTextFields(fieldClassNames) {
  const uniqueIds = new Set();

  fieldClassNames.forEach((className) => {
    document.querySelectorAll(className).forEach((field) => {
      extractUserIds(field.value).forEach((id) => uniqueIds.add(id));
    });
  });
  return [...uniqueIds];
}

async function fetchUsers(ids) {
  if (ids.length <= 0) {
    return new UserStore();
  }
  return await UserStore.fetch(generateFetchUrl(ids));
}

const fetchSuggestions = async (term, searchOptions = {}) => {
  const searchParams = new URLSearchParams();
  searchParams.append('limit', 10);
  searchParams.append('search', term);
  const userStore = await UserStore.fetch(
    `/admin/member_manager/users.json?${searchParams}`,
  );
  return userStore.search(term, searchOptions);
};

async function convertUserIdFieldToUsernameField(targetField, users) {
  targetField.type = 'hidden';

  const inputId = `auto${targetField.id}`;
  const newDiv = document.createElement('div');
  targetField.parentElement.append(newDiv);

  const value = users.matchingIds(extractUserIds(targetField.value));

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
}

async function convertCoAuthorIdsToUsernameInputs(targetField, users) {
  targetField.type = 'hidden';

  const exceptAuthorId = targetField.form.querySelector(
    'input[name="article[user_id]"]',
  )?.value;

  const searchOptions = exceptAuthorId ? { except: exceptAuthorId } : {};
  const inputId = `auto${targetField.id}`;
  const newDiv = document.createElement('div');
  targetField.parentElement.append(newDiv);

  const value = users.matchingIds(extractUserIds(targetField.value));

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
      fetchSuggestions={(term) => fetchSuggestions(term, searchOptions)}
      handleSelectionsChanged={handleSelectionsChanged}
    />,
    newDiv,
  );
}

export async function convertCoauthorIdsToUsernameInputs(users) {
  const usernameFields = document.querySelectorAll(USERNAME_FIELD_CLASS_NAME);
  for (const targetField of usernameFields) {
    convertUserIdFieldToUsernameField(targetField, users);
  }

  const coAuthorFields = document.querySelectorAll(CO_AUTHOR_FIELD_CLASS_NAME);
  for (const coAuthorField of coAuthorFields) {
    convertCoAuthorIdsToUsernameInputs(coAuthorField, users);
  }
}

document.ready.then(async () => {
  const ids = getAllUserIdsFromTextFields([
    CO_AUTHOR_FIELD_CLASS_NAME,
    USERNAME_FIELD_CLASS_NAME,
  ]);
  const users = await fetchUsers(ids);
  convertCoauthorIdsToUsernameInputs(users);
});
