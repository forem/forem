import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { Options } from './Options';
import { Button } from '@crayons';

const Icon = () => (
  <svg
    width="24"
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    aria-labelledby="75abcb76478519ca4eb9"
  >
    <title id="75abcb76478519ca4eb9">Post options</title>
    <path d="M12 1l9.5 5.5v11L12 23l-9.5-5.5v-11L12 1zm0 2.311L4.5 7.653v8.694l7.5 4.342 7.5-4.342V7.653L12 3.311zM12 16a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z" />
  </svg>
);

export const EditorActions = ({
  onSaveDraft,
  onPublish,
  onClearChanges,
  published,
  edited,
  version,
  passedData,
  onConfigChange,
  submitting,
}) => {
  const [moreConfigShowing, setMoreConfig] = useState(false);

  const isVersion1 = version === 'v1';
  const isVersion2 = version === 'v2';

  const toggleMoreConfig = (e) => {
    e.preventDefault();
    setMoreConfig(!moreConfigShowing);
  };

  if (submitting) {
    return (
      <div className="crayons-article-form__footer">
        <Button className="mr-2 whitespace-nowrap" onClick={onPublish} disabled>
          {published && isVersion2
            ? 'Publishing...'
            : `Saving ${isVersion2 ? 'draft' : ''}...`}
        </Button>
      </div>
    );
  }

  return (
    <div className="crayons-article-form__footer">
      <Button className="mr-2 whitespace-nowrap" onClick={onPublish}>
        {published || isVersion1 ? 'Save changes' : 'Publish'}
      </Button>

      {!(published || isVersion1) && (
        <Button
          variant="secondary"
          className="mr-2 whitespace-nowrap"
          onClick={onSaveDraft}
        >
          Save <span className="hidden s:inline">draft</span>
        </Button>
      )}

      {isVersion2 && (
        <div className="s:relative">
          <Button
            variant="ghost"
            contentType="icon"
            icon={Icon}
            title="Post options"
            onClick={toggleMoreConfig}
          />

          {moreConfigShowing && (
            <Options
              passedData={passedData}
              onConfigChange={onConfigChange}
              onSaveDraft={onSaveDraft}
              moreConfigShowing={moreConfigShowing}
              toggleMoreConfig={toggleMoreConfig}
            />
          )}
        </div>
      )}

      {edited && (
        <Button
          variant="ghost"
          onClick={onClearChanges}
          className="whitespace-nowrap fw-normal"
          size="s"
        >
          Revert <span className="hidden s:inline">new changes</span>
        </Button>
      )}
    </div>
  );
};

EditorActions.propTypes = {
  onSaveDraft: PropTypes.func.isRequired,
  onPublish: PropTypes.func.isRequired,
  published: PropTypes.bool.isRequired,
  edited: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  onClearChanges: PropTypes.func.isRequired,
  passedData: PropTypes.string.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  submitting: PropTypes.bool.isRequired,
};

EditorActions.displayName = 'EditorActions';
