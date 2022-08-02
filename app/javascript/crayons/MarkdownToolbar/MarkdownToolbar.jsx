import { h, cloneElement } from 'preact';
import { useState, useLayoutEffect, useRef } from 'preact/hooks';
import { ImageUploader } from '../../article-form/components/ImageUploader';
import {
  markdownSyntaxFormatters,
  getNewTextAreaValueWithEdits,
} from './markdownSyntaxFormatters';
import OverflowIcon from '@images/overflow-vertical.svg';
import { ButtonNew as Button } from '@crayons';
import { useKeyboardShortcuts } from '@components/useKeyboardShortcuts';
import { BREAKPOINTS, useMediaQuery } from '@components/useMediaQuery';
import { getSelectionData } from '@utilities/textAreaUtils';

// Placeholder text displayed while an image is uploading
const UPLOADING_IMAGE_PLACEHOLDER = '![Uploading image](...)';

const MAX_CORE_FORMATTERS_BY_SCREEN_SIZE = {
  small: 5,
  large: 7,
  extraLarge: 10,
};

const getNumberOfIconsToDisplayInToolbar = ({
  isSmallScreen,
  isLargeScreen,
}) => {
  if (isSmallScreen) {
    return MAX_CORE_FORMATTERS_BY_SCREEN_SIZE.small;
  }
  if (isLargeScreen) {
    return MAX_CORE_FORMATTERS_BY_SCREEN_SIZE.large;
  }
  return MAX_CORE_FORMATTERS_BY_SCREEN_SIZE.extraLarge;
};

/**
 * Returns the next sibling in the DOM which matches the given CSS selector.
 * This makes sure that only toolbar buttons are cycled through on Arrow key press,
 * and not e.g. the hidden file input from ImageUploader
 *
 * @param {HTMLElement} element The current HTML element
 * @param {string} selector The CSS selector to match
 * @returns
 */
const getNextMatchingSibling = (element, selector) => {
  let sibling = element.nextElementSibling;

  while (sibling) {
    if (sibling.matches(selector)) return sibling;
    sibling = sibling.nextElementSibling;
  }
};

/**
 * Returns the previous sibling in the DOM which matches the given CSS selector.
 * This makes sure that only toolbar buttons are cycled through on Arrow key press,
 * and not e.g. the hidden file input from ImageUploader
 *
 * @param {HTMLElement} element The current HTML element
 * @param {string} selector The CSS selector to match
 * @returns
 */
const getPreviousMatchingSibling = (element, selector) => {
  let sibling = element.previousElementSibling;

  while (sibling) {
    if (sibling.matches(selector)) return sibling;
    sibling = sibling.previousElementSibling;
  }
};

/**
 * UI component providing markdown shortcuts, to be inserted into the textarea with the given ID
 *
 * @param {object} props
 * @param {string} props.textAreaId The ID of the textarea the markdown formatting should be added to
 */
export const MarkdownToolbar = ({
  textAreaId,
  additionalSecondaryToolbarElements = [],
}) => {
  const textAreaRef = useRef(null);

  const [overflowMenuOpen, setOverflowMenuOpen] = useState(false);
  const [storedCursorPosition, setStoredCursorPosition] = useState({});
  const smallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Medium - 1}px)`);
  const largeScreen = useMediaQuery(
    `(min-width: ${BREAKPOINTS.Large}px) and (max-width: ${
      BREAKPOINTS.ExtraLarge - 1
    }px)`,
  );

  const overflowMenuRows = smallScreen ? 2 : 1;

  // Enhance any additional toolbar elements with the appropriate roles & listeners
  const additionalSecondaryItems = additionalSecondaryToolbarElements.map(
    (SecondaryItem) =>
      cloneElement(SecondaryItem, {
        role: 'menuitem',
        className: 'overflow-menu-btn',
        tabindex: '-1',
        onKeyUp: (e) => handleToolbarButtonKeyPress(e, 'overflow-menu-btn'),
      }),
  );

  const keyboardShortcuts = Object.fromEntries(
    Object.keys(markdownSyntaxFormatters)
      .filter(
        (syntaxName) =>
          !!markdownSyntaxFormatters[syntaxName].getKeyboardShortcut,
      )
      .map((syntaxName) => {
        const { command } =
          markdownSyntaxFormatters[syntaxName].getKeyboardShortcut();
        return [
          command,
          (e) => {
            e.preventDefault();
            insertSyntax(syntaxName);
          },
        ];
      }),
  );

  useKeyboardShortcuts(keyboardShortcuts, textAreaRef.current);

  useLayoutEffect(() => {
    textAreaRef.current = document.getElementById(textAreaId);
  }, [textAreaId]);

  useLayoutEffect(() => {
    // If a user resizes their screen, make sure roving tabindex continues to operate
    const focusableToolbarButton = document.querySelector(
      '.toolbar-btn[tabindex="0"]',
    );
    if (!focusableToolbarButton) {
      document.querySelector('.toolbar-btn').setAttribute('tabindex', '0');
    }
  }, [smallScreen, largeScreen]);

  useLayoutEffect(() => {
    const clickOutsideHandler = ({ target }) => {
      if (target.id !== 'overflow-menu-button') {
        setOverflowMenuOpen(false);
      }
    };

    const escapePressHandler = ({ key }) => {
      if (key === 'Escape') {
        setOverflowMenuOpen(false);
        document.getElementById('overflow-menu-button').focus();
      }
      if (key === 'Tab') {
        setOverflowMenuOpen(false);
      }
    };

    if (overflowMenuOpen) {
      document
        .getElementById('overflow-menu')
        .getElementsByClassName('overflow-menu-btn')[0]
        .focus();

      document.addEventListener('keyup', escapePressHandler);
      document.addEventListener('click', clickOutsideHandler);
    } else {
      document.removeEventListener('keyup', escapePressHandler);
      document.removeEventListener('click', clickOutsideHandler);
    }

    return () => {
      document.removeEventListener('keyup', escapePressHandler);
      document.removeEventListener('click', clickOutsideHandler);
    };
  }, [overflowMenuOpen]);

  // Handles keyboard 'roving tabindex' pattern for toolbar
  const handleToolbarButtonKeyPress = (event, className) => {
    const { key, target } = event;

    const nextButton = getNextMatchingSibling(target, `.${className}`);
    const previousButton = getPreviousMatchingSibling(target, `.${className}`);

    switch (key) {
      case 'ArrowRight':
        event.preventDefault();
        target.setAttribute('tabindex', '-1');
        if (nextButton) {
          nextButton.setAttribute('tabindex', 0);
          nextButton.focus();
        } else {
          const firstButton = document.querySelector(`.${className}`);
          firstButton.setAttribute('tabindex', '0');
          firstButton.focus();
        }
        break;
      case 'ArrowLeft':
        event.preventDefault();
        target.setAttribute('tabindex', '-1');
        if (previousButton) {
          previousButton.setAttribute('tabindex', 0);
          previousButton.focus();
        } else {
          const allButtons = document.getElementsByClassName(className);
          const lastButton = allButtons[allButtons.length - 1];
          lastButton.setAttribute('tabindex', '0');
          lastButton.focus();
        }
        break;
      case 'ArrowDown':
        if (target.id === 'overflow-menu-button') {
          event.preventDefault();
          setOverflowMenuOpen(true);
        }
        break;
    }
  };

  const insertSyntax = (syntaxName) => {
    setOverflowMenuOpen(false);

    const { current: textArea } = textAreaRef;
    const {
      newCursorStart,
      newCursorEnd,
      editSelectionStart,
      editSelectionEnd,
      replaceSelectionWith,
    } = markdownSyntaxFormatters[syntaxName].getFormatting(textArea);

    // We try to update the textArea with document.execCommand, which requires the contentEditable attribute to be true.
    // The value is later toggled back to 'false'
    textArea.contentEditable = 'true';
    textArea.focus({ preventScroll: true });
    textArea.setSelectionRange(editSelectionStart, editSelectionEnd);

    try {
      // We first try to use execCommand which allows the change to be correctly added to the undo queue.
      // document.execCommand is deprecated, but the API which will eventually replace it is still incoming (https://w3c.github.io/input-events/)
      if (replaceSelectionWith === '') {
        document.execCommand('delete', false);
      } else {
        document.execCommand('insertText', false, replaceSelectionWith);
      }
    } catch {
      // In the event of any error using execCommand, we make sure the text area updates (but undo queue will not)
      textArea.value = getNewTextAreaValueWithEdits({
        textAreaValue: textArea.value,
        editSelectionStart,
        editSelectionEnd,
        replaceSelectionWith,
      });
    }

    textArea.contentEditable = 'false';
    textArea.dispatchEvent(new Event('input'));
    textArea.setSelectionRange(newCursorStart, newCursorEnd);
  };

  const handleImageUploadStarted = () => {
    const { current: textArea } = textAreaRef;
    const { textBeforeSelection, textAfterSelection } =
      getSelectionData(textArea);

    const { selectionEnd } = storedCursorPosition;

    const textWithPlaceholder = `${textBeforeSelection}\n${UPLOADING_IMAGE_PLACEHOLDER}${textAfterSelection}`;
    textArea.value = textWithPlaceholder;
    // Make sure Editor text area updates via linkstate
    textArea.dispatchEvent(new Event('input'));

    textArea.focus({ preventScroll: true });

    // Set cursor to the end of the placeholder
    const newCursorPosition =
      selectionEnd + UPLOADING_IMAGE_PLACEHOLDER.length + 1;

    textArea.setSelectionRange(newCursorPosition, newCursorPosition);
  };

  const handleImageUploadEnd = (imageMarkdown = '') => {
    const { current: textArea } = textAreaRef;

    const {
      selectionStart,
      selectionEnd,
      value: currentTextAreaValue,
    } = textArea;

    const indexOfPlaceholder = currentTextAreaValue.indexOf(
      UPLOADING_IMAGE_PLACEHOLDER,
    );

    // User has deleted placeholder, nothing to do
    if (indexOfPlaceholder === -1) return;

    const newTextValue = textArea.value.replace(
      UPLOADING_IMAGE_PLACEHOLDER,
      imageMarkdown,
    );

    textArea.value = newTextValue;
    // Make sure Editor text area updates via linkstate
    textArea.dispatchEvent(new Event('input'));

    // The change to image markdown length does not affect cursor position
    if (indexOfPlaceholder > selectionStart) {
      textArea.setSelectionRange(selectionStart, selectionEnd);
      return;
    }

    const differenceInLength =
      imageMarkdown.length - UPLOADING_IMAGE_PLACEHOLDER.length;

    textArea.setSelectionRange(
      selectionStart + differenceInLength,
      selectionEnd + differenceInLength,
    );
  };

  const numberOfCoreFormatters = getNumberOfIconsToDisplayInToolbar({
    isSmallScreen: smallScreen,
    isLargeScreen: largeScreen,
  });

  const coreSyntaxFormatters = Object.fromEntries(
    Object.entries(markdownSyntaxFormatters).slice(0, numberOfCoreFormatters),
  );
  const secondarySyntaxFormatters = Object.fromEntries(
    Object.entries(markdownSyntaxFormatters).slice(numberOfCoreFormatters),
  );

  const secondaryFormatterButtons = Object.keys(secondarySyntaxFormatters).map(
    (controlName, index) => {
      const { icon, label, getKeyboardShortcut } =
        secondarySyntaxFormatters[controlName];

      return (
        <Button
          key={`${controlName}-btn`}
          role="menuitem"
          icon={icon}
          className="overflow-menu-btn mr-1"
          tabindex={index === 0 ? '0' : '-1'}
          onClick={() => insertSyntax(controlName)}
          onKeyUp={(e) => handleToolbarButtonKeyPress(e, 'overflow-menu-btn')}
          aria-label={label}
          tooltip={
            smallScreen ? null : (
              <span aria-hidden="true">
                {label}
                {getKeyboardShortcut ? (
                  <span className="opacity-75">
                    {` ${getKeyboardShortcut().tooltipHint}`}
                  </span>
                ) : null}
              </span>
            )
          }
        />
      );
    },
  );

  return (
    <div
      className="editor-toolbar"
      aria-label="Markdown formatting toolbar"
      role="toolbar"
      aria-controls={textAreaId}
    >
      {Object.keys(coreSyntaxFormatters).map((controlName, index) => {
        const { icon, label, getKeyboardShortcut } =
          coreSyntaxFormatters[controlName];
        return (
          <Button
            key={`${controlName}-btn`}
            icon={icon}
            className="toolbar-btn mr-1"
            tabindex={index === 0 ? '0' : '-1'}
            onClick={() => insertSyntax(controlName)}
            onKeyUp={(e) => handleToolbarButtonKeyPress(e, 'toolbar-btn')}
            aria-label={label}
            tooltip={
              smallScreen ? null : (
                <span aria-hidden="true">
                  {label}
                  {getKeyboardShortcut ? (
                    <span className="opacity-75">
                      {` ${getKeyboardShortcut().tooltipHint}`}
                    </span>
                  ) : null}
                </span>
              )
            }
          />
        );
      })}

      <ImageUploader
        editorVersion="v2"
        onImageUploadStart={handleImageUploadStarted}
        onImageUploadSuccess={handleImageUploadEnd}
        onImageUploadError={handleImageUploadEnd}
        buttonProps={{
          onKeyUp: (e) => handleToolbarButtonKeyPress(e, 'toolbar-btn'),
          onClick: () => {
            const {
              current: { selectionStart, selectionEnd },
            } = textAreaRef;
            setStoredCursorPosition({ selectionStart, selectionEnd });
          },
          tooltip: smallScreen ? null : (
            <span aria-hidden="true">Upload image</span>
          ),
          key: 'image-btn',
          className: 'toolbar-btn formatter-btn mr-1',
          tabindex: '-1',
        }}
      />

      <Button
        id="overflow-menu-button"
        onClick={() => setOverflowMenuOpen(!overflowMenuOpen)}
        onKeyUp={(e) => handleToolbarButtonKeyPress(e, 'toolbar-btn')}
        aria-expanded={overflowMenuOpen ? 'true' : 'false'}
        aria-haspopup="true"
        icon={OverflowIcon}
        className="toolbar-btn ml-auto"
        tabindex="-1"
        aria-label="More options"
      />

      {overflowMenuOpen && (
        <div
          id="overflow-menu"
          role="menu"
          className={`crayons-dropdown grid grid-rows-${overflowMenuRows} grid-flow-col p-2 min-w-unset right-0 top-100`}
        >
          {secondaryFormatterButtons}
          {additionalSecondaryItems}
        </div>
      )}
    </div>
  );
};
