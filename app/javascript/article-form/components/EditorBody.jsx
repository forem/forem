import { h } from 'preact';
import PropTypes from 'prop-types';
import { useEffect, useLayoutEffect, useRef } from 'preact/hooks';
import { locale } from '@utilities/locale';
import { Toolbar } from './Toolbar';
import { handleImagePasted } from './pasteImageHelpers';
import { handleURLPasted, URL_REGEX } from './pasteURLHelpers';
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
import { gatherPriorityUserIds } from '../../shared/helpers/contextUsers';

// Zero-width space inserted after '@' to break the server-side and client-side
// mention match (\B@[a-z0-9_-]+) without visibly changing the pasted text.
const ZERO_WIDTH_SPACE = '\u200B';
const MENTION_REGEX = /\B@([a-z0-9_-]+)/gi;

/**
 * Splits text into alternating prose and code segments. Fenced code blocks
 * (``` or ~~~) and inline code spans (`...`) are preserved verbatim so their
 * contents are never treated as mentions.
 *
 * @param {string} text
 * @returns {{ code: boolean, text: string }[]} Ordered segments.
 */
const splitCodeSegments = (text) => {
  // Matches a fenced block (```...``` or ~~~...~~~) or an inline code span.
  const codePattern = /(```[\s\S]*?(?:```|$)|~~~[\s\S]*?(?:~~~|$)|`[^`\n]*`)/g;
  const segments = [];
  let lastIndex = 0;
  let match;

  while ((match = codePattern.exec(text)) !== null) {
    if (match.index > lastIndex) {
      segments.push({ code: false, text: text.slice(lastIndex, match.index) });
    }
    segments.push({ code: true, text: match[0] });
    lastIndex = codePattern.lastIndex;
  }

  if (lastIndex < text.length) {
    segments.push({ code: false, text: text.slice(lastIndex) });
  }

  return segments;
};

/**
 * Inserts a zero-width space after '@' for mention-like tokens found in prose,
 * leaving fenced blocks and inline code spans untouched.
 *
 * @param {string} text The pasted text.
 * @returns {string} The text with prose mentions neutralized.
 */
const neutralizeMentionsOutsideCode = (text) =>
  splitCodeSegments(text)
    .map((segment) =>
      segment.code
        ? segment.text
        : segment.text.replace(MENTION_REGEX, `@${ZERO_WIDTH_SPACE}$1`),
    )
    .join('');

/**
 * Determines whether the end of the given text sits inside an unterminated code
 * fence or inline code span. Used to detect when the paste cursor is already
 * inside code in the existing editor content.
 *
 * @param {string} text Editor content up to the cursor.
 * @returns {boolean} True if the cursor is inside open code.
 */
const isInsideCode = (text) => {
  // Odd number of fence markers means a fence is still open.
  const fenceCount = (text.match(/```|~~~/g) || []).length;
  if (fenceCount % 2 === 1) return true;

  // Within the current line, an odd number of backticks means an open inline span.
  const currentLine = text.slice(text.lastIndexOf('\n') + 1);
  const backtickCount = (currentLine.match(/`/g) || []).length;
  return backtickCount % 2 === 1;
};

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
  }, [setElement, setPasteElement]);

  // If it's a URL, embed as a URL. Otherwise paste as plain text with
  // accidental @mentions neutralized (outside of code).
  useEffect(() => {
    // Make sure we are in the editor
    const textarea = textAreaRef.current;
    if (!textarea) return;

    const urlHandler = handleURLPasted(textAreaRef);

    // Handle text that was pasted into the editor
    const onPaste = (e) => {
      // If files are present in the clipboard, let the image paste handler deal with it
      const types = e.clipboardData?.types;
      if (types && (types.includes?.('Files') || types.contains?.('Files'))) {
        return;
      }

      // Get the clipboard data
      const dt = e.clipboardData || window.clipboardData;
      const pastedText = dt?.getData?.('text/plain') ?? '';

      if (!pastedText) return; // If no text, do not proceed

      const trimmed = pastedText.trim();

      // If it's a URL, treat it as a URL
      const isProbablyURL = URL_REGEX.test(trimmed);
      if (isProbablyURL) {
        urlHandler(e);
        return;
      }

      // If the cursor is already inside an open code fence/span in the
      // existing content, the paste lands in code too. Leave it untouched so
      // we never corrupt code the author is writing.
      const textBeforeCursor = textarea.value.slice(
        0,
        textarea.selectionStart,
      );
      if (isInsideCode(textBeforeCursor)) return;

      // Neutralize @mentions in prose only (skip fenced and inline code), so a
      // pasted "@handle" in a sentence isn't linked server-side by
      // Html::Parser#wrap_mentions_with_links or picked up by the editor's
      // autocomplete. A zero-width space after '@' breaks the \B@ match.
      const neutralized = neutralizeMentionsOutsideCode(pastedText);

      // Nothing changed (e.g. the whole paste is code) — let the browser
      // handle it normally to preserve the undo stack.
      if (neutralized === pastedText) return;

      e.preventDefault();

      // Prefer execCommand so the change is added to the native undo stack.
      const el = textarea;
      let inserted = false;
      try {
        el.focus();
        inserted = document.execCommand('insertText', false, neutralized);
      } catch {
        inserted = false;
      }

      if (!inserted) {
        // Fallback for environments without execCommand support.
        const start = el.selectionStart;
        const end = el.selectionEnd;
        if (typeof el.setRangeText === 'function') {
          el.setRangeText(neutralized, start, end, 'end');
        } else {
          const before = el.value.slice(0, start);
          const after = el.value.slice(end);
          el.value = before + neutralized + after;
          el.selectionStart = el.selectionEnd = (before + neutralized).length;
        }
        el.dispatchEvent(new Event('input', { bubbles: true }));
      }
    };

    textarea.addEventListener('paste', onPaste);
    return () => textarea.removeEventListener('paste', onPaste);
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
        fetchSuggestions={(username) => {
          const priorityUserIds = gatherPriorityUserIds(textAreaRef.current);
          const params = { username };

          if (priorityUserIds.length) {
            params.priority_user_ids = priorityUserIds;
          }

          return fetchSearch('usernames', params).then(({ result }) =>
            result.map((user) => ({ ...user, value: user.username })),
          );
        }}
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