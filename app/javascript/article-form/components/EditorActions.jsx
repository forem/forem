import { h, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import moment from 'moment';
import PropTypes from 'prop-types';
import { Options } from './Options';
import { AiDisclosureModal } from './AiDisclosureModal';
import { ButtonNew as Button } from '@crayons';
import { locale } from '@utilities/locale';
import RobotIcon from '@images/robot.svg';

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
  switchHelpContext,
  aiDisclosureSignal,
}) => {
  const isVersion1 = version === 'v1';
  const isVersion2 = version === 'v2';

  if (submitting) {
    return (
      <div className="crayons-article-form__footer flex items-center">
        <Button
          variant="primary"
          onClick={onPublish}
          disabled
        >
          {published && isVersion2
            ? 'Publishing...'
            : `Saving ${isVersion2 ? 'post' : ''}...`}
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

  // Extract advanced options for footer display
  const { canonicalUrl = '', series = '', publishedAtDate: scheduleDate = '', publishedAtTime: scheduleTime = '' } = passedData;
  const hasAdvancedOptions = canonicalUrl || series || (scheduleDate && scheduleTime && schedule);
  const [optionsModalSignal, setOptionsModalSignal] = useState(0);
  const [isAiModalOpen, setIsAiModalOpen] = useState(false);
  const [disclosureRequired, setDisclosureRequired] = useState(false);

  // articleForm bumps this signal when a publish is blocked on disclosure.
  useEffect(() => {
    if (aiDisclosureSignal) {
      setDisclosureRequired(true);
      setIsAiModalOpen(true);
    }
  }, [aiDisclosureSignal]);

  const reopenOptionsModal = () => {
    setOptionsModalSignal((prev) => prev + 1);
  };

  const aiDisclosureLabels = {
    no_ai: 'No AI',
    some_ai: 'Some AI',
    fully_autonomous: 'Fully Autonomous',
  };
  const currentAiLevel = passedData.aiDisclosureLevel;
  const hasAiDisclosure = currentAiLevel && currentAiLevel !== 'not_disclosed';
  const aiLabel = aiDisclosureLabels[currentAiLevel];

  let saveButtonText;
  if (isVersion1) {
    saveButtonText = locale('core.article_form_save_changes');
  } else if (schedule) {
    saveButtonText = locale('core.article_form_schedule');
  } else if (wasScheduled || !published) {
    // if the article was saved as scheduled, and the user clears publishedAt in the post options, the save button text is changed to "Publish"
    // to make it clear that the article is going to be published right away
    saveButtonText = locale('core.article_form_publish');
  } else {
    saveButtonText = locale('core.article_form_save_changes');
  }

  return (
    <div
      id="editor-actions"
      className="crayons-article-form__footer flex items-center gap-2"
      onMouseEnter={switchHelpContext}
    >
      <div className="flex items-center flex-wrap gap-2">
        <Button
          variant="primary"
          onClick={onPublish}
          disabled={previewLoading}
          onFocus={(event) => switchHelpContext(event, 'editor-actions')}
        >
          {saveButtonText}
        </Button>

        {!(published || isVersion1) && (
          <Button
            variant="secondary"
            onClick={onSaveDraft}
            disabled={previewLoading}
            onFocus={(event) => switchHelpContext(event, 'editor-actions')}
          >
            Save <span className="hidden s:inline">Draft</span>
          </Button>
        )}

        {isVersion2 && passedData?.aiDisclosureEnabled && (
          <>
            <Button
              id="post-ai-disclosure-btn"
              icon={RobotIcon}
              title="AI Disclosure options"
              aria-label="AI Disclosure options"
              disabled={previewLoading}
              onClick={(e) => {
                e.preventDefault();
                setIsAiModalOpen(true);
              }}
            >
              <span className="hidden xl:inline-block ml-1">
                {hasAiDisclosure ? `AI: ${aiLabel}` : 'AI Disclosure'}
              </span>
            </Button>

            <AiDisclosureModal
              currentValue={currentAiLevel || 'not_disclosed'}
              isOpen={isAiModalOpen}
              required={disclosureRequired}
              onClose={() => setIsAiModalOpen(false)}
              onChange={onConfigChange}
            />
          </>
        )}

        {isVersion2 && (
          <Options
            passedData={passedData}
            schedulingEnabled={schedulingEnabled}
            onConfigChange={onConfigChange}
            onSaveDraft={onSaveDraft}
            previewLoading={previewLoading}
            externalOpenSignal={optionsModalSignal}
            onFocus={(event) => switchHelpContext(event, 'editor-actions')}
          />
        )}

        {hasAdvancedOptions && isVersion2 && (
          <div className="article-form-footer-pills hidden m:flex items-center gap-2">
            {scheduleDate && scheduleTime && schedule && (
              <button
                type="button"
                className="article-form-footer-pill cursor-pointer"
                title={publishedAtObj.format('MMMM D, YYYY [at] h:mm A')}
                onClick={reopenOptionsModal}
              >
                ⏰ Scheduled
              </button>
            )}
            {canonicalUrl && (
              <button
                type="button"
                className="article-form-footer-pill cursor-pointer"
                title={canonicalUrl}
                onClick={reopenOptionsModal}
              >
                🔗 Canonical
              </button>
            )}
            {series && (
              <button
                type="button"
                className="article-form-footer-pill cursor-pointer"
                title={`Series: ${series}`}
                onClick={reopenOptionsModal}
              >
                📚 {series}
              </button>
            )}
          </div>
        )}

        {edited && (
          <Button
            onClick={onClearChanges}
            className="whitespace-nowrap color-base-60 hover:color-accent-danger fs-xs"
            disabled={previewLoading}
            onFocus={(event) => switchHelpContext(event, 'editor-actions')}
          >
            Revert <span className="hidden s:inline">new changes</span>
          </Button>
        )}
      </div>
    </div>
  );
};

EditorActions.propTypes = {
  aiDisclosureSignal: PropTypes.number,
  onSaveDraft: PropTypes.func.isRequired,
  onPublish: PropTypes.func.isRequired,
  published: PropTypes.bool.isRequired,
  publishedAtTime: PropTypes.string.isRequired,
  publishedAtDate: PropTypes.string.isRequired,
  schedulingEnabled: PropTypes.bool, // Kept for backward compatibility but always true now
  edited: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  onClearChanges: PropTypes.func.isRequired,
  passedData: PropTypes.object.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  submitting: PropTypes.bool.isRequired,
  previewLoading: PropTypes.bool.isRequired,
};

EditorActions.displayName = 'EditorActions';
