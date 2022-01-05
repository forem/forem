import { h } from 'preact';
import PropTypes from 'prop-types';
import { locale } from '../../utilities/locale';
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
            ? locale('views.editor.actions.publishing')
            : `${locale('views.editor.actions.saving')} ${
                isVersion2 ? locale('views.editor.actions.draft') : ''
              }...`}
        </Button>
      </div>
    );
  }

  return (
    <div className="crayons-article-form__footer">
      <Button className="mr-2 whitespace-nowrap" onClick={onPublish}>
        {published || isVersion1
          ? locale('views.editor.actions.save')
          : locale('views.editor.actions.publish')}
      </Button>

      {!(published || isVersion1) && (
        <Button
          variant="secondary"
          className="mr-2 whitespace-nowrap"
          onClick={onSaveDraft}
        >
          {locale('views.editor.actions.save')}{' '}
          <span className="hidden s:inline">
            {locale('views.editor.actions.draft')}
          </span>
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
          {locale('views.editor.actions.revert')}{' '}
          <span className="hidden s:inline">
            {locale('views.editor.actions.changes')}
          </span>
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
