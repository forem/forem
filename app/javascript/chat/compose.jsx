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
    editMessageHtml: PropTypes.string.isRequired,
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
      editMessageHtml,
    } = this.props;

    return (
      <div className="messagecomposer">
        <div className="messageToBeEdited">
          <div className="message">
            <span className="editHead">Edit Message</span>
            <div
              // eslint-disable-next-line react/no-danger
              dangerouslySetInnerHTML={{
                __html: editMessageHtml,
              }}
            />
          </div>
          <div
            className="closeEdit"
            role="button"
            onClick={handleEditMessageClose}
            tabIndex="0"
            onKeyUp={e => {
              if (e.keyCode === 13) handleEditMessageClose();
            }}
          >
            x
          </div>
        </div>
        <textarea
          className="messagecomposer__input"
          id="messageform"
          placeholder="Message goes here"
          onKeyDown={handleKeyDownEdit}
          onKeyPress={handleMention}
          onKeyUp={handleKeyUp}
          maxLength="1000"
        />
        <button
          type="button"
          className="messagecomposer__submit cta"
          onClick={handleSubmitOnClickEdit}
        >
          Save
        </button>
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
          className="messagecomposer__input"
          id="messageform"
          placeholder="Message goes here"
          onKeyDown={handleKeyDown}
          onKeyPress={handleMention}
          onKeyUp={handleKeyUp}
          maxLength="1000"
        />
        <button
          type="button"
          className="messagecomposer__submit cta"
          onClick={handleSubmitOnClick}
        >
          SEND
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
