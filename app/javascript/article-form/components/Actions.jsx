import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';
import { Options } from './Options';

export const Actions = ({
  onSaveDraft,
  onPublish,
  onClearChanges,
  published,
  edited,
  version,
  passedData,
  onConfigChange,
  toggleMoreConfig,
  moreConfigShowing,
  submitting
}) => {
  const Icon = () => (
    <svg
      width="24"
      className="crayons-icon"
      height="24"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M12 1l9.5 5.5v11L12 23l-9.5-5.5v-11L12 1zm0 2.311L4.5 7.653v8.694l7.5 4.342 7.5-4.342V7.653L12 3.311zM12 16a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z" />
    </svg>
  );

  return (
    <div>
      {submitting && (
        <div className="crayons-layout crayons-article-form__actions">
          <Button className="mr-2" onClick={onPublish} disabled>
            {published && version === 'v2'
              ? 'Publishing...'
              : `Saving ${version === 'v2' ? 'draft' : ''}...`}
          </Button>
        </div>
      )}

      {!submitting && (
        <div className="crayons-layout crayons-article-form__actions">
          <Button className="mr-2" onClick={onPublish}>
            {published || version === 'v1' ? 'Save changes' : 'Publish'}
          </Button>

          {published || version === 'v1' ? (
            ''
          ) : (
            <Button variant="secondary" className="mr-2" onClick={onSaveDraft}>
              Save draft
            </Button>
          )}
          <div className="relative">
            <Button
              variant="ghost"
              contentType="icon"
              icon={Icon}
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
          <p style={!edited && { visibility: 'hidden' }}>
            <Button variant="ghost" onClick={onClearChanges} size="s">
              Clear new changes
            </Button>
          </p>
        </div>
      )}
    </div>
  );
}

Actions.propTypes = {
  onSaveDraft: PropTypes.func.isRequired,
  onPublish: PropTypes.func.isRequired,
  published: PropTypes.bool.isRequired,
  edited: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  onClearChanges: PropTypes.func.isRequired,
  passedData: PropTypes.string.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  toggleMoreConfig: PropTypes.func.isRequired,
  moreConfigShowing: PropTypes.bool.isRequired,
  submitting: PropTypes.bool.isRequired
};

Actions.displayName = 'Actions';
