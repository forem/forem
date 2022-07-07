import { h } from 'preact';
import PropTypes from 'prop-types';
import { Options } from './Options';
import { ButtonNew as Button } from '@crayons';

export const EditorActions = ({
  onSaveDraft,
  onPublish,
  onClearChanges,
  published,
  publishedAt,
  schedulingEnabled,
  edited,
  version,
  passedData,
  onConfigChange,
  submitting,
  previewLoading,
}) => {
  const isVersion1 = version === 'v1';
  const isVersion2 = version === 'v2';

  if (submitting) {
    return (
      <div className="crayons-article-form__footer">
        <Button
          variant="primary"
          className="mr-2 whitespace-nowrap"
          onClick={onPublish}
          disabled
        >
          {published && isVersion2
            ? 'Publishing...'
            : `Saving ${isVersion2 ? 'draft' : ''}...`}
        </Button>
      </div>
    );
  }

  const now = new Date();
  const publishedAtDate = publishedAt ? new Date(publishedAt) : now;
  const schedule = publishedAtDate > now;

  const saveButtonText = schedule
    ? 'Schedule'
    : published || isVersion1
    ? 'Save changes'
    : 'Publish';

  return (
    <div className="crayons-article-form__footer">
      <Button
        variant="primary"
        className="mr-2 whitespace-nowrap"
        onClick={onPublish}
        disabled={previewLoading}
      >
        {saveButtonText}
      </Button>

      {!(published || isVersion1) && (
        <Button
          className="mr-2 whitespace-nowrap"
          onClick={onSaveDraft}
          disabled={previewLoading}
        >
          Save <span className="hidden s:inline">draft</span>
        </Button>
      )}

      {isVersion2 && (
        <Options
          passedData={passedData}
          schedulingEnabled={schedulingEnabled}
          onConfigChange={onConfigChange}
          onSaveDraft={onSaveDraft}
          previewLoading={previewLoading}
        />
      )}

      {edited && (
        <Button
          onClick={onClearChanges}
          className="whitespace-nowrap fw-normal fs-s"
          disabled={previewLoading}
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
  publishedAt: PropTypes.string.isRequired,
  schedulingEnabled: PropTypes.bool.isRequired,
  edited: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  onClearChanges: PropTypes.func.isRequired,
  passedData: PropTypes.object.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  submitting: PropTypes.bool.isRequired,
  previewLoading: PropTypes.bool.isRequired,
};

EditorActions.displayName = 'EditorActions';
