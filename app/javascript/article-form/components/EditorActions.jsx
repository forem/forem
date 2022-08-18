import { h } from 'preact';
import moment from 'moment';
import PropTypes from 'prop-types';
import { Options } from './Options';
import { ButtonNew as Button } from '@crayons';

export const EditorActions = ({
  onSaveDraft,
  onPublish,
  onClearChanges,
  published,
  publishedAtDate,
  publishedAtTime,
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

  const now = moment();
  const publishedAtObj = publishedAtDate
    ? moment(`${publishedAtDate} ${publishedAtTime || '00:00'}`)
    : now;
  const schedule = publishedAtObj > now;
  const wasScheduled = passedData.publishedAtWas > now;

  let saveButtonText;
  if (isVersion1) {
    saveButtonText = 'Save changes';
  } else if (schedule) {
    saveButtonText = 'Schedule';
  } else if (wasScheduled || !published) {
    // if the article was saved as scheduled, and the user clears publishedAt in the post options, the save button text is changed to "Publish"
    // to make it clear that the article is going to be published right away
    saveButtonText = 'Publish';
  } else {
    saveButtonText = 'Save changes';
  }

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
  publishedAtTime: PropTypes.string.isRequired,
  publishedAtDate: PropTypes.string.isRequired,
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
