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

// For any line containing a pipe, replace `\|` with `&#124;` automatically.
const normalizeEscapedPipes = (text) => {
  const lines = text.split('\n');
  let inFence = false;
  const fenceRe = /^\s*```/;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (fenceRe.test(line)) {
      inFence = !inFence;
      continue;
    }

    if (!inFence && line.includes('|')) {
      lines[i] = line.replace(/\\\|/g, '&#124;');
    }
  }

  return lines.join('\n');
};

export const EditorBody = ({
  onChange,
  defaultValue,
  switchHelpContext,
  version,
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
  
  // normalize \| to &#124; on lines with pipes, outside code fences.
  const handleBodyChange = (e) => {
    const el = e?.target;
    if (!el) {
      onChange?.(e);
      return;
    }

    const original = el.value;
    const normalized = normalizeEscapedPipes(original);

    if (normalized !== original) {
      const start = el.selectionStart;
      const end = el.selectionEnd;

      // Compute how normalization affects text length before the selection,
      // so we can adjust caret/selection positions accordingly.
      const beforeStartOriginal = original.slice(0, start);
      const beforeEndOriginal = original.slice(0, end);
      const beforeStartNormalized = normalizeEscapedPipes(beforeStartOriginal);
      const beforeEndNormalized = normalizeEscapedPipes(beforeEndOriginal);

      const deltaStart = beforeStartNormalized.length - beforeStartOriginal.length;
      const deltaEnd = beforeEndNormalized.length - beforeEndOriginal.length;

      let newStart = start + deltaStart;
      let newEnd = end + deltaEnd;

      // Clamp selection to the bounds of the new text.
      const maxPos = normalized.length;
      if (newStart < 0) newStart = 0;
      if (newEnd < 0) newEnd = 0;
      if (newStart > maxPos) newStart = maxPos;
      if (newEnd > maxPos) newEnd = maxPos;

      el.value = normalized;
      try {
        el.setSelectionRange(newStart, newEnd);
      } catch {
        // ignore selection errors
      }
    }

    onChange?.(e);
  };

  return (
    <div
      data-testid="article-form__body"
      className="crayons-article-form__body drop-area text-padding"
    >
      <Toolbar version={version} textAreaId="article_body_markdown" />
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
        onChange={handleBodyChange}
        onFocus={switchHelpContext}
        aria-label="Post Content"
        name="body_markdown"
        id="article_body_markdown"
        defaultValue={defaultValue}
        placeholder={locale('core.editor_body_placeholder')}
        className="crayons-textfield crayons-textfield--ghost crayons-article-form__body__field ff-monospace fs-l h-100"
      />
    </div>
  );
};

EditorBody.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  version: PropTypes.string.isRequired,
};

EditorBody.displayName = 'EditorBody';