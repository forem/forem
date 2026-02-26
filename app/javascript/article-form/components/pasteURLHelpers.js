import { getCursorXY } from '@utilities/textAreaUtils';

const URL_REGEX = /^https?:\/\/\S+$/;
const POPOVER_ID = 'embed-url-popover';
const POPOVER_TIMEOUT_MS = 5000;

/**
 * Remove any existing embed popover from the DOM.
 */
function removePopover() {
  const existing = document.getElementById(POPOVER_ID);
  if (existing) existing.remove();
}

/**
 * Handler for when a URL is pasted into the editor.
 * Shows an inline popover near the cursor offering to convert the URL into an embed tag.
 *
 * @param {object} textAreaRef A Preact ref to the textarea element.
 */
export function handleURLPasted(textAreaRef) {
  return function (event) {
    if (!event.clipboardData) return;

    // Skip if this is a file paste (let image handler deal with it)
    if (event.clipboardData.types.includes('Files')) return;

    const pastedText = event.clipboardData.getData('text/plain').trim();
    if (!URL_REGEX.test(pastedText)) return;

    // Record cursor position before paste is applied
    const textarea = textAreaRef.current;
    if (!textarea) return;
    const insertPos = textarea.selectionStart;

    // Only offer embed when pasting on its own line — embeds are block-level content.
    // If pasting mid-paragraph, the user likely wants an inline link, not an embed.
    const textBefore = textarea.value.substring(0, insertPos);
    const lineStart = textBefore.lastIndexOf('\n') + 1;
    const textOnLineBefore = textBefore.substring(lineStart).trim();
    if (textOnLineBefore.length > 0) return;

    // Let the URL paste normally, then show the popover
    setTimeout(() => {
      removePopover();

      // Skip if the pasted URL is already inside a liquid tag (e.g. {% embed ... %})
      const currentValue = textarea.value;
      const before = currentValue.substring(0, insertPos);
      const after = currentValue.substring(insertPos + pastedText.length);
      if (before.match(/\{%\s*embed\s+$/) && after.match(/^\s*%\}/)) return;

      // Calculate position at the end of the pasted URL
      const cursorPos = insertPos + pastedText.length;
      let x = 0;
      let y = 0;
      try {
        const pos = getCursorXY({
          input: textarea,
          selectionPoint: cursorPos,
        });
        x = pos.x;
        y = pos.y;
      } catch {
        // Fallback: position below the textarea's top
        const rect = textarea.getBoundingClientRect();
        x = rect.left;
        y = rect.top + 20;
      }

      const popover = document.createElement('div');
      popover.id = POPOVER_ID;
      popover.className = 'c-autocomplete__popover absolute';
      popover.style.cssText = `
        top: calc(${y}px + 1.5rem);
        left: ${x}px;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.375rem 0.5rem;
        width: auto;
      `;

      const label = document.createElement('span');
      label.textContent = 'Embed this link?';
      label.style.whiteSpace = 'nowrap';

      const embedBtn = document.createElement('button');
      embedBtn.textContent = 'Embed';
      embedBtn.className = 'crayons-btn crayons-btn--s';

      const dismissBtn = document.createElement('button');
      dismissBtn.textContent = 'Dismiss';
      dismissBtn.className = 'crayons-btn crayons-btn--s crayons-btn--ghost';

      const replaceWithEmbed = () => {
        const el = textAreaRef.current;
        if (!el) return;

        const { value } = el;
        const embedTag = `{% embed ${pastedText} %}`;

        // Verify the URL is still at the expected position
        if (
          value.substring(insertPos, insertPos + pastedText.length) ===
          pastedText
        ) {
          el.value =
            value.substring(0, insertPos) +
            embedTag +
            value.substring(insertPos + pastedText.length);
        } else {
          // Fallback: replace last occurrence
          const lastIndex = value.lastIndexOf(pastedText);
          if (lastIndex === -1) return;
          el.value =
            value.substring(0, lastIndex) +
            embedTag +
            value.substring(lastIndex + pastedText.length);
        }

        // Sync form state
        el.dispatchEvent(new Event('input'));
        removePopover();
      };

      embedBtn.addEventListener('click', replaceWithEmbed);
      dismissBtn.addEventListener('click', removePopover);

      popover.appendChild(label);
      popover.appendChild(embedBtn);
      popover.appendChild(dismissBtn);
      document.body.appendChild(popover);

      // Auto-dismiss after timeout
      const timeoutId = setTimeout(removePopover, POPOVER_TIMEOUT_MS);

      // Dismiss on next keypress in textarea
      const onKeyDown = () => {
        clearTimeout(timeoutId);
        removePopover();
        textarea.removeEventListener('keydown', onKeyDown);
      };
      textarea.addEventListener('keydown', onKeyDown);
    }, 0);
  };
}
