import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '../../i18n/l10n';
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
          {i18next.t(
            published && isVersion2
              ? 'editor.publishing'
              : isVersion2
              ? 'editor.saving_draft'
              : 'editor.saving',
          )}
        </Button>
      </div>
    );
  }

  return (
    <div className="crayons-article-form__footer">
      <Button className="mr-2 whitespace-nowrap" onClick={onPublish}>
        {i18next.t(published || isVersion1 ? 'editor.save' : 'editor.publish')}
      </Button>

      {!(published || isVersion1) && (
        <Button
          variant="secondary"
          className="mr-2 whitespace-nowrap"
          onClick={onSaveDraft}
          dangerouslySetInnerHTML={{
            __html: i18next.t('editor.save_draft', {
              start: '<span className="hidden s:inline">',
              end: '</span>',
            }),
          }}
        />
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
          dangerouslySetInnerHTML={{
            __html: i18next.t('editor.revert_button', {
              start: '<span className="hidden s:inline">',
              end: '</span>',
            }),
          }}
        />
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
