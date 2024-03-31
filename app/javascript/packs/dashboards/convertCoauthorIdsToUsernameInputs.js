import { h, render } from 'preact';
import { UsernameInput } from '@components/UsernameInput';
import { UserStore } from '@components/UserStore';
import '@utilities/document_ready';

async function fetchAllUsers(fetchUrls) {
  const users = await Promise.all(
    fetchUrls.map((fetchUrl) =>
      UserStore.fetch(fetchUrl).then((data) => [fetchUrl, data]),
    ),
  );
  return new Map(users);
}

function extractFetchUrl(field) {
  return field.dataset.fetchUsers;
}

function extractFetchUrls(fields) {
  const urls = [...fields].map((field) => extractFetchUrl(field));
  return [...new Set(urls)];
}

export async function convertCoauthorIdsToUsernameInputs() {
  const usernameFields = document.getElementsByClassName(
    'article_org_co_author_ids_list',
  );

  const fetchUrls = extractFetchUrls(usernameFields);
  const usersMap = await fetchAllUsers(fetchUrls);

  for (const targetField of usernameFields) {
    targetField.type = 'hidden';
    const exceptAuthorId =
      targetField.form.querySelector('#article_user_id').value;
    const inputId = `auto${targetField.id}`;

    const users = usersMap.get(extractFetchUrl(targetField));
    const row = targetField.parentElement;

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
  }
}

document.ready.then(() => {
  convertCoauthorIdsToUsernameInputs();
});
