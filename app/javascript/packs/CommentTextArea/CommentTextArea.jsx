import { h } from 'preact';
import { useState, useRef, useLayoutEffect } from 'preact/hooks';
import { populateTemplates } from '../../responseTemplates/responseTemplates';
import { handleImagePasted } from '../../article-form/components/pasteImageHelpers';
import {
  handleImageDrop,
  handleImageFailure,
  onDragOver,
  onDragExit,
} from '../../article-form/components/dragAndDropHelpers';

import {
  AutocompleteTriggerTextArea,
  MarkdownToolbar,
  Link,
  ButtonNew as Button,
} from '@crayons';
import { fetchSearch } from '@utilities/search';
import HelpIcon from '@images/help.svg';
import Templates from '@images/templates.svg';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';

const getClosestTemplatesContainer = (element) =>
  element
    .closest('.comment-form__inner')
    ?.querySelector('.response-templates-container');

const handleImageSuccess = (textAreaRef) => {
  return function (response) {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;
    const { links } = response;

    const markdownImageLink = `![Image description](${links[0]})\n`;
    const { selectionStart, selectionEnd, value } = editableBodyElement;
    const before = value.substring(0, selectionStart);
    const after = value.substring(selectionEnd, value.length);

    editableBodyElement.value = `${before + markdownImageLink} ${after}`;
    editableBodyElement.selectionStart =
      selectionStart + markdownImageLink.length;
    editableBodyElement.selectionEnd = editableBodyElement.selectionStart;
  };
};

export const CommentTextArea = ({ vanillaTextArea }) => {
  const [templatesVisible, setTemplatesVisible] = useState(false);
  const textAreaRef = useRef(null);
  const contextData = document.getElementById('comments-container')?.dataset;

  const { setElement } = useDragAndDrop({
    onDrop: handleImageDrop(
      handleImageSuccess(textAreaRef),
      handleImageFailure,
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageSuccess(textAreaRef),
      handleImageFailure,
    ),
  });

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

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setPasteElement(textAreaRef.current);
      setElement(textAreaRef.current);
    }
  }, [setPasteElement, setElement]);

  return (
    <div className="w-100 relative drop-area">
      <AutocompleteTriggerTextArea
        ref={textAreaRef}
        triggerCharacter="@"
        maxSuggestions={6}
        searchInstructionsMessage="Type to search for a user"
        replaceElement={vanillaTextArea}
        fetchSuggestions={(username) =>
          fetchSearch('usernames', {
            username,
            context_type: contextData?.['commentableType'],
            context_id: contextData?.['commentableId'],
          }).then(({ result }) =>
            result?.map((user) => ({ ...user, value: user.username })),
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
