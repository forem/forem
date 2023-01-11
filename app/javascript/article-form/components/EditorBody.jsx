import { h } from 'preact';
import PropTypes from 'prop-types';
import { useLayoutEffect, useRef, useState } from 'preact/hooks';
import ReactImageGrid from '@cordelia273/react-image-grid';
import { Toolbar } from './Toolbar';
import { handleImagePasted } from './pasteImageHelpers';
import { ImageUploader } from './ImageUploader';
import {
  handleImageUploadSuccess,
  handleImageUploading,
  handleImageUploadFailure,
} from './imageUploadHelpers';
import { handleImageDrop, onDragOver, onDragExit } from './dragAndDropHelpers';
import { TagsField } from './TagsField';
import { EmojiPicker, GifPicker } from '@crayons';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';
import { fetchSearch } from '@utilities/search';
import { AutocompleteTriggerTextArea } from '@crayons/AutocompleteTriggerTextArea';
import { BREAKPOINTS, useMediaQuery } from '@components/useMediaQuery';

export const EditorBody = ({
  onChange,
  defaultValue,
  tagsDefaultValue,
  tagsOnInput,
  imagesDefaultValue,
  imagesOnInput,
  onMainImageUrlChange,
  switchHelpContext,
  version,
}) => {
  const textAreaRef = useRef(null);

  const [images, setImages] = useState(
    imagesDefaultValue != '' ? imagesDefaultValue.split(',') : [],
  );
  const smallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Medium - 1}px)`);

  document.addEventListener('upload_image_success', (e) => {
    const imagesList = [...images, ...e.detail];
    setImages(imagesList);
    imagesOnInput(imagesList.join(','));
    onMainImageUrlChange({
      links: [
        (location.href.includes('localhost') ||
        location.href.includes('host.docker.internal')
          ? location.origin
          : '') + imagesList[0],
      ],
    });
  });

  const { setElement } = useDragAndDrop({
    onDrop: handleImageDrop(
      handleImageUploading(textAreaRef),
      handleImageUploadSuccess(textAreaRef, version),
      handleImageUploadFailure(textAreaRef),
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageUploading(textAreaRef),
      handleImageUploadSuccess(textAreaRef, version),
      handleImageUploadFailure(textAreaRef),
    ),
  });

  useLayoutEffect(() => {
    if (textAreaRef.current) {
      setElement(textAreaRef.current);
      setPasteElement(textAreaRef.current);
    }
  });

  // const handleImageUploadStarted = () => {

  // }

  // const handleImageUploadEnd = (imageMarkdown = '') => {

  // };

  return (
    <div
      data-testid="article-form__body"
      className="crayons-article-form__body drop-area text-padding"
      // style={version == 'v0' ? {'padding-top' : 0} : null}
    >
      {version == 'v0' ? null : (
        <Toolbar version={version} textAreaId="article_body_markdown" />
      )}
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
        aria-label="Post Content"
        name="body_markdown"
        id="article_body_markdown"
        defaultValue={defaultValue}
        placeholder="Write your post content here..."
        className="crayons-textfield crayons-textfield--ghost crayons-article-form__body__field ff-monospace fs-l h-100"
      />

      {version == 'v0' ? (
        <div
          style={{
            border: '1px solid #ddd',
            'border-radius': '0.5rem',
            padding: '0.5rem',
          }}
        >
          Add to your post{' '}
          <ImageUploader
            editorVersion="v2"
            // onImageUploadStart={handleImageUploadStarted}
            // onImageUploadSuccess={handleImageUploadEnd}
            // onImageUploadError={handleImageUploadEnd}
            buttonProps={{
              // onKeyUp: (e) => handleToolbarButtonKeyPress(e, 'toolbar-btn'),
              onClick: () => {},
              tooltip: <span aria-hidden="true">Upload image</span>,
              key: 'image-btn',
              className: 'toolbar-btn formatter-btn mr-1',
              tabindex: '-1',
            }}
          />
          {smallScreen ? null : <EmojiPicker textAreaRef={textAreaRef} />}
          <GifPicker textAreaRef={textAreaRef} />
        </div>
      ) : null}

      {version === 'v0' && (
        <div
          className="crayons-article-form__top drop-area"
          style={{ padding: '0.5rem 0' }}
        >
          <TagsField
            defaultValue={tagsDefaultValue}
            onInput={tagsOnInput}
            switchHelpContext={switchHelpContext}
          />
        </div>
      )}

      {version === 'v0' ? (
        <div style={{ maxWidth: 800, maxHeight: 400, height: 400 }}>
          <ReactImageGrid images={images} modal={false} />
        </div>
      ) : null}
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
