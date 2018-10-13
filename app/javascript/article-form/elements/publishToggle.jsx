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
    <button onClick={onPublish} className="articleform__buttons--publish">
      {published ? 'SAVE CHANGES' : 'PUBLISH'}
    </button>
  </div>
);

PublishToggle.propTypes = {
  defaultValue: PropTypes.string.isRequired,
};

export default PublishToggle;
