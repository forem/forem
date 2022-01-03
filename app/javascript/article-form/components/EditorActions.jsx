import { h } from 'preact';
import PropTypes from 'prop-types';
import { Options } from './Options';
import { Button } from '@crayons';

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
  const isVersion1 = version === 'v1';
  const isVersion2 = version === 'v2';

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
        <Options
          passedData={passedData}
          onConfigChange={onConfigChange}
          onSaveDraft={onSaveDraft}
        />
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
  passedData: PropTypes.object.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  submitting: PropTypes.bool.isRequired,
};

EditorActions.displayName = 'EditorActions';
