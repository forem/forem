import { h } from 'preact';
import PropTypes from 'prop-types';

const PublishToggle = ({
  previewShowing,
  onPreview,
  onSaveDraft,
  onPublish,
  onHelp,
  published,
  helpShowing,
  edited,
  version,
  onClearChanges,
}) => (
  <div className="articleform__buttons">
    <button
      onClick={onHelp}
      type="button"
      className={
        helpShowing
          ? 'articleform__buttons--small active'
          : 'articleform__buttons--small inactive'
      }
    >
      ?
    </button>
    <button
      onClick={onPreview}
      type="button"
      className={previewShowing ? 'active' : 'inactive'}
    >
      {previewShowing ? 'EDIT' : 'PREVIEW'}
    </button>
    {published || version === 'v1' ? (
      ''
    ) : (
      <button onClick={onSaveDraft} type="button">
        SAVE DRAFT
      </button>
    )}
    <span>
      <p style={!edited && { visibility: 'hidden' }}>
        New Changes (
        <button onClick={onClearChanges} className="clear-button" type="button">
          clear
        </button>
        )
      </p>
      <button
        onClick={onPublish}
        className="articleform__buttons--publish"
        type="button"
      >
        {published || version === 'v1' ? 'SAVE CHANGES' : 'PUBLISH'}
      </button>
    </span>
  </div>
);

PublishToggle.propTypes = {
  previewShowing: PropTypes.bool.isRequired,
  onPreview: PropTypes.func.isRequired,
  onSaveDraft: PropTypes.func.isRequired,
  onPublish: PropTypes.func.isRequired,
  onHelp: PropTypes.func.isRequired,
  published: PropTypes.bool.isRequired,
  helpShowing: PropTypes.bool.isRequired,
  edited: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  onClearChanges: PropTypes.func.isRequired,
};

export default PublishToggle;
