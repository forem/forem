const KEY_CODE_B = 66;
const KEY_CODE_I = 73;
const KEY_CODE_K = 75;

export function handleKeyDown(e) {
  if (e.ctrlKey || e.metaKey) {
    switch (e.keyCode) {
      case KEY_CODE_B:
        e.preventDefault();
        handleBoldAndItalic(e);
        break;
      case KEY_CODE_I:
        e.preventDefault();
        handleBoldAndItalic(e);
        break;
      case KEY_CODE_K:
        e.preventDefault();
        handleLink(e);
        break;
      default:
        break;
    }
  }
}

function handleBoldAndItalic(event) {
  const textArea = event.target;

  const selection = textArea.value.substring(
    textArea.selectionStart,
    textArea.selectionEnd,
  );
  const selectionStart = textArea.selectionStart;
  const surroundingStr = event.keyCode === KEY_CODE_B ? '**' : '_';

  replaceSelectedText(
    textArea,
    `${surroundingStr}${selection}${surroundingStr}`,
  );

  const selectionStartWithOffset = selectionStart + surroundingStr.length;
  textArea.setSelectionRange(
    selectionStartWithOffset,
    selectionStartWithOffset + selection.length,
  );
}

function handleLink(event) {
  const textArea = event.target;

  const selection = textArea.value.substring(
    textArea.selectionStart,
    textArea.selectionEnd,
  );
  const selectionStart = textArea.selectionStart;

  replaceSelectedText(textArea, `[${selection}](url)`);

  // start position + length of selection + [](
  const startOffset = selectionStart + selection.length + 3;

  // start offset + 'url'.length
  const endOffset = startOffset + 3;

  textArea.setSelectionRange(startOffset, endOffset);
}

function replaceSelectedText(textArea, text) {
  // Chrome and other modern browsers (except FF and IE 8,9,10,11)
  if (document.execCommand('insertText', false, text)) {
  }
  // Firefox (non-standard method)
  else if (typeof textArea.setRangeText === 'function') {
    textArea.setRangeText(text);
  }
}
