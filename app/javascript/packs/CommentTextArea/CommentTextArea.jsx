import { h } from 'preact';

import { MentionAutocompleteTextArea, MarkdownToolbar } from '@crayons';
import { fetchSearch } from '@utilities/search';

export const CommentTextArea = ({ vanillaTextArea }) => {
  // TODO: customise primary/secondary toolbar options
  //   TODO: ability to apply classes to toolbar wrapper
  return (
    <div>
      <MentionAutocompleteTextArea
        replaceElement={vanillaTextArea}
        fetchSuggestions={(username) => fetchSearch('usernames', { username })}
      />
      <MarkdownToolbar textAreaId={vanillaTextArea.id} />
    </div>
  );
};
