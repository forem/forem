import { h } from 'preact';
import PropTypes from 'prop-types';

const PublishToggle = ({ previewShowing, onPreview, onSaveDraft, onPublish, onHelp, published, helpShowing }) => (
  <div className="articleform__buttons">
    <button onClick={onHelp} className={helpShowing ? "active" : "inactive" }>
      HELP
    </button>
    <button onClick={onPreview} className={previewShowing ? "active" : "inactive" }>
      PREVIEW
    </button>
    <button onClick={onSaveDraft}>
      {published ? 'UNPUBLISH' : 'SAVE DRAFT' }
    </button>
    <button onClick={onPublish}>
      {published ? 'SAVE CHANGES' : 'PUBLISH' }
    </button>

  </div>
);

PublishToggle.propTypes = {
  defaultValue: PropTypes.string.isRequired,
};

export default PublishToggle;
