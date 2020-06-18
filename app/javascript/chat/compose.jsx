import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export default class Chat extends Component {
  static propTypes = {
    handleKeyDown: PropTypes.func.isRequired,
    handleKeyDownEdit: PropTypes.func.isRequired,
    handleSubmitOnClick: PropTypes.func.isRequired,
    handleSubmitOnClickEdit: PropTypes.func.isRequired,
    handleMention: PropTypes.func.isRequired,
    handleKeyUp: PropTypes.func.isRequired,
    startEditing: PropTypes.bool.isRequired,
    markdownEdited: PropTypes.bool.isRequired,
    editMessageMarkdown: PropTypes.string.isRequired,
    handleEditMessageClose: PropTypes.func.isRequired,
  };

  componentDidUpdate() {
    const { editMessageMarkdown, markdownEdited, startEditing } = this.props;
    const textarea = document.getElementById('messageform');
    if (!markdownEdited && startEditing) {
      textarea.value = editMessageMarkdown;
    }
  }

  messageCompose = () => {
    const {
      handleSubmitOnClickEdit,
      handleKeyDownEdit,
      handleEditMessageClose,
      handleMention,
      handleKeyUp,
    } = this.props;

    return (
      <div className="composer-container__edit">
        <textarea
          className="crayons-textfield composer-textarea composer-textarea__edit"
          id="messageform"
          placeholder="Let's connect"
          onKeyDown={handleKeyDownEdit}
          onKeyPress={handleMention}
          onKeyUp={handleKeyUp}
          maxLength="1000"
        />
        <div className="composer-btn-group">
          <button
            type="button"
            className="composer-submit composer-submit__edit crayons-btn"
            onClick={handleSubmitOnClickEdit}
          >
            Save
          </button>
          <div
            role="button"
            className="composer-close__edit crayons-btn crayons-btn--secondary"
            onClick={handleEditMessageClose}
            tabIndex="0"
            onKeyUp={(e) => {
              if (e.keyCode === 13) handleEditMessageClose();
            }}
          >
            Close
          </div>
        </div>
      </div>
    );
  };

  textAreaSection = () => {
    const {
      handleSubmitOnClick,
      handleKeyDown,
      handleMention,
      handleKeyUp,
    } = this.props;
    return (
      <div className="messagecomposer">
        <textarea
          className="crayons-textfield composer-textarea"
          id="messageform"
          placeholder="Write message..."
          onKeyDown={handleKeyDown}
          onKeyPress={handleMention}
          onKeyUp={handleKeyUp}
          maxLength="1000"
        />
        <button
          type="button"
          className="crayons-btn composer-submit"
          onClick={handleSubmitOnClick}
        >
          Send
        </button>
      </div>
    );
  };

  render() {
    const { startEditing } = this.props;
    return (
      <div className="compose__outer__container">
        {!startEditing ? this.textAreaSection() : this.messageCompose()}
      </div>
    );
  }
}
