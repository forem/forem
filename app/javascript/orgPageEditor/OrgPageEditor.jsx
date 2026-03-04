import { h } from 'preact';
import { useRef, useLayoutEffect } from 'preact/hooks';
import { MarkdownToolbar } from '@crayons';
import { AutocompleteTriggerTextArea } from '@crayons/AutocompleteTriggerTextArea';
import { fetchSearch } from '@utilities/search';
import { handleImagePasted } from '../article-form/components/pasteImageHelpers';
import {
  handleImageUploadSuccess,
  handleImageUploading,
  handleImageUploadFailure,
} from '../article-form/components/imageUploadHelpers';
import { handleImageDrop, onDragOver, onDragExit } from '../article-form/components/dragAndDropHelpers';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';

const TEXTAREA_ID = 'org_page_markdown';

export const OrgPageEditor = ({ defaultValue, textAreaName }) => {
  const textAreaRef = useRef(null);

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

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setElement(textAreaRef.current);
      setPasteElement(textAreaRef.current);
    }
  });

  return (
    <div className="crayons-article-form__body drop-area">
      <div className="crayons-article-form__toolbar">
        <MarkdownToolbar textAreaId={TEXTAREA_ID} />
      </div>
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        maxSuggestions={6}
        searchInstructionsMessage="Type to search for a user"
        ref={textAreaRef}
        fetchSuggestions={(username) =>
          fetchSearch('usernames', { username }).then(({ result }) =>
            result.map((user) => ({ ...user, value: user.username })),
          )
        }
        autoResize
        aria-label="Page content"
        name={textAreaName}
        id={TEXTAREA_ID}
        defaultValue={defaultValue}
        placeholder="Use Markdown and Liquid tags to customize your org page.&#10;&#10;Example:&#10;{% org_team your-org-slug %}&#10;{% org_posts your-org-slug %}"
        className="crayons-textfield crayons-textfield--ghost ff-monospace fs-l"
        style={{ minHeight: '400px' }}
      />
    </div>
  );
};

OrgPageEditor.displayName = 'OrgPageEditor';
