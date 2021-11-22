import { h } from 'preact';
import { useState, useLayoutEffect } from 'preact/hooks';
import { ImageUploader } from '../../article-form/components/ImageUploader';
import {
  coreSyntaxFormatters,
  secondarySyntaxFormatters,
} from './markdownSyntaxFormatters';
import { Overflow, Help } from './icons';
import { Button } from '@crayons';
import { KeyboardShortcuts } from '@components/useKeyboardShortcuts';
import { BREAKPOINTS, useMediaQuery } from '@components/useMediaQuery';
import { getSelectionData } from '@utilities/textAreaUtils';

// Placeholder text displayed while an image is uploading
const UPLOADING_IMAGE_PLACEHOLDER = '![Uploading image](...)';

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
export const MarkdownToolbar = ({ textAreaId }) => {
  const [textArea, setTextArea] = useState(null);
  const [overflowMenuOpen, setOverflowMenuOpen] = useState(false);
  const smallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Medium - 1}px)`);

  const markdownSyntaxFormatters = {
    ...coreSyntaxFormatters,
    ...secondarySyntaxFormatters,
  };

  const keyboardShortcuts = Object.fromEntries(
    Object.keys(markdownSyntaxFormatters)
      .filter(
        (syntaxName) =>
          !!markdownSyntaxFormatters[syntaxName].getKeyboardShortcut,
      )
      .map((syntaxName) => {
        const { command } =
          markdownSyntaxFormatters[syntaxName].getKeyboardShortcut?.();
        return [command, () => insertSyntax(syntaxName)];
      }),
  );

  useLayoutEffect(() => {
    setTextArea(document.getElementById(textAreaId));
  }, [textAreaId]);

  useLayoutEffect(() => {
    // If a user resizes their screen, make sure roving tabindex continues to operate
    const focusableToolbarButton = document.querySelector(
      '.toolbar-btn[tabindex="0"]',
    );
    if (!focusableToolbarButton) {
      document.querySelector('.toolbar-btn').setAttribute('tabindex', '0');
    }
  }, [smallScreen]);

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

    const { newTextAreaValue, newCursorStart, newCursorEnd } =
      markdownSyntaxFormatters[syntaxName].getFormatting(textArea);

    textArea.value = newTextAreaValue;
    textArea.dispatchEvent(new Event('input'));
    textArea.focus({ preventScroll: true });
    textArea.setSelectionRange(newCursorStart, newCursorEnd);
  };

  const handleImageUploadStarted = () => {
    const { textBeforeSelection, textAfterSelection, selectionEnd } =
      getSelectionData(textArea);

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

  const handleImageUploadSuccess = (imageMarkdown) => {
    const newTextValue = textArea.value.replace(
      UPLOADING_IMAGE_PLACEHOLDER,
      imageMarkdown,
    );
    textArea.value = newTextValue;
    // Make sure Editor text area updates via linkstate
    textArea.dispatchEvent(new Event('input'));
  };

  const handleImageUploadError = () => {
    const newTextValue = textArea.value.replace(
      UPLOADING_IMAGE_PLACEHOLDER,
      '',
    );
    textArea.value = newTextValue;
    // Make sure Editor text area updates via linkstate
    textArea.dispatchEvent(new Event('input'));
  };

  const getSecondaryFormatterButtons = (isOverflow) =>
    Object.keys(secondarySyntaxFormatters).map((controlName, index) => {
      const { icon, label, getKeyboardShortcut } =
        secondarySyntaxFormatters[controlName];

      return (
        <Button
          key={`${controlName}-btn`}
          role={isOverflow ? 'menuitem' : 'button'}
          variant="ghost"
          contentType="icon"
          icon={icon}
          className={
            isOverflow
              ? 'overflow-menu-btn hidden m:block mr-2'
              : 'toolbar-btn m:hidden mr-2'
          }
          tabindex={isOverflow && index === 0 ? '0' : '-1'}
          onClick={() => insertSyntax(controlName)}
          onKeyUp={(e) =>
            handleToolbarButtonKeyPress(
              e,
              isOverflow ? 'overflow-menu-btn' : 'toolbar-btn',
            )
          }
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
    });

  return (
    <div
      className="editor-toolbar relative overflow-x-auto m:overflow-visible"
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
            variant="ghost"
            contentType="icon"
            icon={icon}
            className="toolbar-btn mr-2"
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
        onImageUploadSuccess={handleImageUploadSuccess}
        onImageUploadError={handleImageUploadError}
        buttonProps={{
          onKeyUp: (e) => handleToolbarButtonKeyPress(e, 'toolbar-btn'),
          tooltip: smallScreen ? null : (
            <span aria-hidden="true">Upload image</span>
          ),
          key: 'image-btn',
          variant: 'ghost',
          contentType: 'icon',
          className: 'toolbar-btn formatter-btn',
          tabindex: '-1',
        }}
      />

      {smallScreen ? getSecondaryFormatterButtons(false) : null}

      {smallScreen ? null : (
        <Button
          id="overflow-menu-button"
          onClick={() => setOverflowMenuOpen(!overflowMenuOpen)}
          onKeyUp={(e) => handleToolbarButtonKeyPress(e, 'toolbar-btn')}
          aria-expanded={overflowMenuOpen ? 'true' : 'false'}
          aria-haspopup="true"
          variant="ghost"
          contentType="icon"
          icon={Overflow}
          className="toolbar-btn ml-auto hidden m:block"
          tabindex="-1"
          aria-label="More options"
        />
      )}

      {overflowMenuOpen && (
        <div
          id="overflow-menu"
          role="menu"
          className="crayons-dropdown flex p-2 min-w-unset right-0 top-100"
        >
          {getSecondaryFormatterButtons(true)}
          <Button
            tagName="a"
            role="menuitem"
            url="/p/editor_guide"
            variant="ghost"
            contentType="icon"
            icon={Help}
            className="overflow-menu-btn"
            tabindex="-1"
            aria-label="Help"
            onKeyUp={(e) => handleToolbarButtonKeyPress(e, 'overflow-menu-btn')}
          />
        </div>
      )}
      {textArea && (
        <KeyboardShortcuts
          shortcuts={keyboardShortcuts}
          eventTarget={textArea}
        />
      )}
    </div>
  );
};
