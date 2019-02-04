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
  onClearChanges,
}) => (
  <div className="articleform__buttons">
    <button
      onClick={onHelp}
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
      className={previewShowing ? 'active' : 'inactive'}
    >
      PREVIEW
    </button>
    {published ? '' : <button onClick={onSaveDraft}>SAVE DRAFT</button>}
    <span>
      <p style={!edited && { visibility: 'hidden' }}>
        New Changes (
        <button onClick={onClearChanges} className="clear-button">
          clear
        </button>
        )
      </p>
      <button onClick={onPublish} className="articleform__buttons--publish">
        {published ? 'SAVE CHANGES' : 'PUBLISH'}
      </button>
    </span>
  </div>
);

PublishToggle.propTypes = {
  defaultValue: PropTypes.string.isRequired,
};

export default PublishToggle;
