import { h, render } from 'preact';
import { useState, useRef, useEffect } from 'preact/hooks';
import ReactGiphySearchbox from 'react-giphy-searchbox';
import PropTypes from 'prop-types';
import {
  autoUpdate,
  computePosition,
  flip,
  offset,
  shift,
} from '@floating-ui/dom';
import styled, { createGlobalStyle } from 'styled-components';
import CloseIcon from './icons/close.svg';
import { ButtonNew as Button } from '@crayons';
import GifIcon from '@images/gif.svg';

const GlobalStyle = createGlobalStyle`
    .reactGiphySearchbox-componentWrapper {
        min-width: 385px !important;

    }
`;

export const GifPicker = ({ textAreaRef }) => {
  const [open, setOpen] = useState(false);
  const [referenceEl, setReferenceEl] = useState(null);
  const [floatingEl, setFloatingEl] = useState(null);
  const floatingElRef = useRef(null);
  let stopAutoUpdate = null;

  useEffect(() => {
    if (
      typeof updatePosition != 'function' ||
      typeof onDocumentClick != 'function'
    ) {
      return;
    }

    if (referenceEl && floatingEl && open) {
      !document.body.contains(floatingEl) &&
        document.body.appendChild(floatingEl);

      floatingEl &&
        Object.assign(floatingEl.style, {
          opacity: 0,
        });

      // eslint-disable-next-line react-hooks/exhaustive-deps
      stopAutoUpdate = autoUpdate(referenceEl, floatingEl, updatePosition);

      floatingEl &&
        Object.assign(floatingEl.style, {
          opacity: 1,
        });
    } else {
      floatingEl &&
        Object.assign(floatingEl.style, {
          opacity: 0,
        });

      stopAutoUpdate?.();
      floatingEl && floatingEl.remove();

      return;
    }

    if (open) {
      document.addEventListener('mousedown', onDocumentClick);
    }

    return () => {
      if (open) {
        document.removeEventListener('mousedown', onDocumentClick);
      }
    };
  }, [open]);

  const onDocumentClick = (e) => {
    const clickedNode = e.target;

    const isClickOnTrigger = referenceEl?.contains(clickedNode);
    const isClickOnPicker = floatingEl?.contains(clickedNode);

    if (open && !isClickOnPicker && !isClickOnTrigger) {
      handleClose();
    }
  };

  const updatePosition = () => {
    if (!referenceEl) {
      return;
    }

    computePosition(referenceEl, floatingEl, {
      placement: 'bottom',
      middleware: [flip(), shift(), offset(5)],
    }).then(({ x, y }) => {
      Object.assign(floatingEl.style, {
        position: 'absolute',

        left: `${x}px`,
        top: `${y}px`,
      });
    });
  };

  const insertGif = (giphy) => {
    const { current: textArea } = textAreaRef;
    const { url: gif } = giphy.images.downsized;
    const { title } = giphy;
    const replaceSelectionWith = `![${title}](${gif})\n\n`;

    const { selectionStart, selectionEnd } = textArea;

    // We try to update the textArea with document.execCommand, which requires the contentEditable attribute to be true.
    // The value is later toggled back to 'false'
    textArea.contentEditable = 'true';
    textArea.focus({ preventScroll: true });
    textArea.setSelectionRange(selectionStart, selectionEnd);

    try {
      // We first try to use execCommand which allows the change to be correctly added to the undo queue.
      // document.execCommand is deprecated, but the API which will eventually replace it is still incoming (https://w3c.github.io/input-events/)
      if (replaceSelectionWith !== '') {
        document.execCommand('insertText', false, replaceSelectionWith);
      }
    } catch {}

    textArea.contentEditable = 'false';
    textArea.dispatchEvent(new Event('input'));
    textArea.setSelectionRange(
      selectionStart + replaceSelectionWith.length,
      selectionEnd + replaceSelectionWith.length,
    );
  };

  const handleClick = (target) => {
    if (
      typeof handleClose != 'function' ||
      typeof insertGif != 'function'
    ) {
      return;
    }

    setReferenceEl(target);

    if (!floatingElRef.current) {
      render(
        <GiphyPickerWrapper ref={floatingElRef} className="giphy-picker">
          <GiphyPickeCloseBtn onClick={handleClose}>
            <CloseIcon />
          </GiphyPickeCloseBtn>
          <ReactGiphySearchbox
            onSelect={insertGif}
            apiKey="LK46acLcGJ1AIzxDG0BYD3iH2PsO4eYP"
            masonryConfig={[{ columns: 3, imageWidth: 120, gutter: 5 }]}
          />
        </GiphyPickerWrapper>,
        document.body,
      );
      setFloatingEl(floatingElRef.current);
    }

    setOpen(!open);
  };

  const handleClose = () => {
    setOpen(false);
  };

  return (
    <span>
      <GlobalStyle />
      <Button
        // ref={reference}
        key="gif-btn"
        className="gif-btn"
        onClick={(e) => {
          if (typeof handleClick != 'function') {
            return;
          }

          handleClick(e.target);
        }}
        icon={GifIcon}
        aria-label="Gif"
        label="Gif"
      />
    </span>
  );
};

GifPicker.propTypes = {
  textAreaRef: PropTypes.object.isRequired,
};

const GiphyPickerWrapper = styled.div`
  position: absolute;
  z-index: 99;
  background-color: #eee;
  border: 1px solid #ccc;
  -webkit-border-radius: 4px;
  -moz-border-radius: 4px;
  border-radius: 4px;
  padding: 5px;
  opacity: 0;
`;

const GiphyPickeCloseBtn = styled.div`
  position: absolute;
  z-index: 100;
  width: 24px;
  height: 24px;
  right: -12px;
  top: -12px;
  background: #999;
  border-radius: 50%;
  cursor: pointer;
`;
