import { h } from 'preact';
import PropTypes from 'prop-types';
import { useEffect, useLayoutEffect, useRef } from 'preact/hooks';
import { locale } from '@utilities/locale';
import { Toolbar } from './Toolbar';
import { handleImagePasted } from './pasteImageHelpers';
import { handleURLPasted } from './pasteURLHelpers';
import {
  handleImageUploadSuccess,
  handleImageUploading,
  handleImageUploadFailure,
} from './imageUploadHelpers';
import { handleImageDrop, onDragOver, onDragExit } from './dragAndDropHelpers';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';
import { fetchSearch } from '@utilities/search';
import { AutocompleteTriggerTextArea } from '@crayons/AutocompleteTriggerTextArea';

export const EditorBody = ({
  onChange,
  defaultValue,
  switchHelpContext,
  version,
  textAreaId = 'article_body_markdown',
  textAreaName = 'body_markdown',
  placeholder,
  ariaLabel = 'Post Content',
  className = 'crayons-textfield crayons-textfield--ghost crayons-article-form__body__field ff-monospace fs-l h-100',
}) => {
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

  // Attach URL paste handler for embed prompt
  useEffect(() => {
    const textarea = textAreaRef.current;
    if (!textarea) return;

    const handler = handleURLPasted(textAreaRef);
    textarea.addEventListener('paste', handler);
    return () => textarea.removeEventListener('paste', handler);
  }, []);

  return (
    <div
      data-testid="article-form__body"
      className="crayons-article-form__body drop-area text-padding"
    >
      <Toolbar version={version} textAreaId={textAreaId} />
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
        onChange={onChange}
        onFocus={switchHelpContext}
        aria-label={ariaLabel}
        name={textAreaName}
        id={textAreaId}
        defaultValue={defaultValue}
        placeholder={placeholder || locale('core.editor_body_placeholder')}
        className={className}
      />
    </div>
  );
};

EditorBody.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func,
  version: PropTypes.string,
  textAreaId: PropTypes.string,
  textAreaName: PropTypes.string,
  placeholder: PropTypes.string,
  ariaLabel: PropTypes.string,
  className: PropTypes.string,
};

EditorBody.displayName = 'EditorBody';
