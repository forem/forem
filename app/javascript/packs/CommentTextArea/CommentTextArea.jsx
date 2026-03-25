import { h, Fragment } from 'preact';
import { useState, useRef, useLayoutEffect } from 'preact/hooks';
import { populateTemplates } from '../../responseTemplates/responseTemplates';
import { createPopup } from '@picmo/popup-picker';
import { addSnackbarItem } from '../../Snackbar';
import { handleImagePasted } from '../../article-form/components/pasteImageHelpers';
import {
  handleImageUploading,
  handleImageUploadSuccess,
  handleImageUploadFailure,
} from '../../article-form/components/imageUploadHelpers';
import {
  handleImageDrop,
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
import EmojiIcon from '@images/emoji.svg';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';
import { gatherPriorityUserIds } from '../../shared/helpers/contextUsers';

const getClosestTemplatesContainer = (element) =>
  element
    .closest('.comment-form__inner')
    ?.querySelector('.response-templates-container');

const insertTextAtCursor = (textArea, text) => {
  const { selectionStart, selectionEnd, value } = textArea;
  const newPos = selectionStart + text.length;

  textArea.contentEditable = 'true';
  textArea.focus({ preventScroll: true });
  textArea.setSelectionRange(selectionStart, selectionEnd);

  if (document.activeElement === textArea) {
    try {
      document.execCommand('insertText', false, text);
    } catch (e) {
      textArea.value = value.slice(0, selectionStart) + text + value.slice(selectionEnd);
    }
  } else {
    // Fallback: if focus trap or race condition prevented focusing the textarea, directly insert
    textArea.value = value.slice(0, selectionStart) + text + value.slice(selectionEnd);
  }

  textArea.contentEditable = 'false';
  textArea.dispatchEvent(new Event('input'));
  
  setTimeout(() => {
    textArea.focus({ preventScroll: true });
    textArea.setSelectionRange(newPos, newPos);
  }, 10);
};

const replacePlaceholder = (textArea, searchPattern, replaceWith) => {
  const { selectionStart, selectionEnd, value } = textArea;
  const index = value.indexOf(searchPattern);
  if (index === -1) return;
  
  textArea.value = value.replace(searchPattern, replaceWith);
  textArea.dispatchEvent(new Event('input'));
  
  const diff = replaceWith.length - searchPattern.length;
  if (index < selectionStart) {
    textArea.setSelectionRange(selectionStart + diff, selectionEnd + diff);
  } else {
    textArea.setSelectionRange(selectionStart, selectionEnd);
  }
};

const EmojiPickerButton = ({ textAreaId }) => {
  const pickerRef = useRef(null);

  const handleClick = (e) => {
    e.preventDefault();
    if (!pickerRef.current) {
      pickerRef.current = createPopup({}, {
        referenceElement: e.currentTarget,
        triggerElement: e.currentTarget,
        position: 'bottom-start',
        className: 'c-emoji-popup'
      });
      pickerRef.current.addEventListener('emoji:select', (event) => {
        pickerRef.current.close();
        const liveTextArea = document.getElementById(textAreaId);
        if (liveTextArea) {
          // 50ms timeout ensures Picmo removes any active focus traps prior to insertion
          setTimeout(() => {
            insertTextAtCursor(liveTextArea, event.emoji);
          }, 50);
        }
      });
    }
    pickerRef.current.toggle();
  };

  return (
    <Button
      key="emoji-btn"
      icon={EmojiIcon}
      aria-label="Insert Emoji"
      tooltip="Insert Emoji"
      onClick={handleClick}
    />
  );
};


export const CommentTextArea = ({ vanillaTextArea }) => {
  const [templatesVisible, setTemplatesVisible] = useState(false);
  const textAreaRef = useRef(null);
  const contextData = document.getElementById('comments-container')?.dataset;

  const { setElement } = useDragAndDrop({
    onDrop: handleImageDrop(
      handleImageUploading(textAreaRef),
      handleImageUploadSuccess(textAreaRef),
      handleImageUploadFailure(textAreaRef),
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageUploading(textAreaRef),
      handleImageUploadSuccess(textAreaRef),
      handleImageUploadFailure(textAreaRef),
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
        fetchSuggestions={(username) => {
          const priorityUserIds = gatherPriorityUserIds(textAreaRef.current);
          return fetchSearch('usernames', {
            username,
            context_type: contextData?.['commentableType'],
            context_id: contextData?.['commentableId'],
            priority_user_ids: priorityUserIds.length ? priorityUserIds : undefined,
          }).then(({ result }) =>
            result?.map((user) => ({ ...user, value: user.username })),
          );
        }}
      />
      <MarkdownToolbar
        textAreaId={vanillaTextArea.id}
        additionalPrimaryToolbarElements={[
          <EmojiPickerButton textAreaId={vanillaTextArea.id} />
        ]}
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
