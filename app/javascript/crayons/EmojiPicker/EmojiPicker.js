import { h } from 'preact';
import { useState } from 'preact/hooks';
import { createPopup } from '@picmo/popup-picker';
import PropTypes from 'prop-types';
import { ButtonNew as Button } from '@crayons';
import EmojiIcon from '@images/emoji.svg';

export const EmojiPicker = ({ textAreaRef }) => {
    const [picker, setPicker] = useState(null);
    
    const insertEmoji = (textAreaRef, emoji) => {
        const { current: textArea } = textAreaRef;

        const {
            selectionStart,
            selectionEnd
        } = textArea;

        // We try to update the textArea with document.execCommand, which requires the contentEditable attribute to be true.
        // The value is later toggled back to 'false'
        textArea.contentEditable = 'true';
        textArea.focus({ preventScroll: true });
        textArea.setSelectionRange(selectionStart, selectionEnd);

        try {
            // We first try to use execCommand which allows the change to be correctly added to the undo queue.
            // document.execCommand is deprecated, but the API which will eventually replace it is still incoming (https://w3c.github.io/input-events/)
            if (emoji !== '') {
                document.execCommand('insertText', false, emoji);
            }
        } catch {
        }

        textArea.contentEditable = 'false';
        textArea.dispatchEvent(new Event('input'));
        textArea.setSelectionRange(selectionStart + emoji.length, selectionEnd + emoji.length);
    };

    const handleEmojiClick = (textAreaRef, target) => {
        if (typeof createPopup != 'function') {
            return;
        }

        if (picker == null) {
            let popupPicker = createPopup({
                emojisPerRow: 7,
                theme: 'auto',
                visibleRows: 5
            }, {
                triggerElement: target,
                referenceElement: target,
                position: "bottom",
                hideOnClickOutside: true,
                hideOnEmojiSelect: false,
                hideOnEscape: true,
                className: "emoji-popup"
            });

            // The picker emits an event when an emoji is selected. Do with it as you will!
            popupPicker.addEventListener('emoji:select', event => {
                if (typeof insertEmoji != 'function') {
                    return;
                }

                insertEmoji(textAreaRef, event.emoji);
            });

            popupPicker.toggle();
            setPicker(popupPicker);
        } else {
            picker.toggle();
        }
    }

    return (
        <Button
        key="emoji-btn"
        className="emoji-btn"
        onClick={(e) => {
            if (typeof handleEmojiClick != 'function') {
                return;
            }

            handleEmojiClick(textAreaRef, e.target)
        }}
        icon={EmojiIcon}
        aria-label="Emoji"
        label="Emoji"
       />
    );
};
  
EmojiPicker.propTypes = {
    textAreaRef: PropTypes.object.isRequired
};