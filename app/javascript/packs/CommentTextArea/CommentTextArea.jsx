import { h } from 'preact';
import { useState } from 'preact/hooks';
import { populateTemplates } from '../../responseTemplates/responseTemplates';

import {
  AutocompleteTriggerTextArea,
  MarkdownToolbar,
  Link,
  ButtonNew as Button,
} from '@crayons';
import { fetchSearch } from '@utilities/search';
import HelpIcon from '@images/help.svg';
import Templates from '@images/templates.svg';

const getClosestTemplatesContainer = (element) =>
  element
    .closest('.comment-form__inner')
    ?.querySelector('.response-templates-container');

export const CommentTextArea = ({ vanillaTextArea }) => {
  const [templatesVisible, setTemplatesVisible] = useState(false);

  // Templates appear outside of the comment textarea, but we only want to load this data if it's requested by the user
  const handleTemplatesClick = ({ target }) => {
    const templatesContainer = getClosestTemplatesContainer(target);
    const relatedForm = target.closest('form');

    if (templatesContainer && relatedForm) {
      populateTemplates(relatedForm, () => {
        setTemplatesVisible(false);
        templatesContainer.classList.add('hidden');
      });
      templatesContainer.classList.toggle('hidden');
      setTemplatesVisible(!templatesVisible);
    }
  };

  return (
    <div className="w-100 relative">
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        maxSuggestions={6}
        searchInstructionsMessage="Type to search for a user"
        replaceElement={vanillaTextArea}
        fetchSuggestions={(username) =>
          fetchSearch('usernames', { username }).then(({ result }) =>
            result.map((user) => ({ ...user, value: user.username })),
          )
        }
      />
      <MarkdownToolbar
        textAreaId={vanillaTextArea.id}
        additionalSecondaryToolbarElements={[
          <Button
            key="templates-btn"
            onClick={handleTemplatesClick}
            icon={Templates}
            aria-label="Show templates"
            aria-pressed={templatesVisible}
          />,
          <Link
            key="help-link"
            block
            href="/p/editor_guide"
            target="_blank"
            rel="noopener noreferrer"
            icon={HelpIcon}
            aria-label="Help"
          />,
        ]}
      />
    </div>
  );
};
