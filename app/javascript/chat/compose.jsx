import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';

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
    handleFilePaste: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      value: null,
    };
  }

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
      handleFilePaste,
    } = this.props;

    return (
      <div className="composer-container__edit">
        <Textarea
          className="crayons-textfield composer-textarea__edit"
          id="messageform"
          placeholder="Let's connect"
          onKeyDown={handleKeyDownEdit}
          onKeyPress={handleMention}
          onKeyUp={handleKeyUp}
          onPaste={handleFilePaste}
          maxLength="1000"
          aria-label="Let's connect"
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
      handleFilePaste,
    } = this.props;

    const handleInput = (e) => {
      this.setState({
        value: e.target.value,
      });
    };

    const handleOnSubmitAction = (e) => {
      handleSubmitOnClick(e);

      this.setState({
        value: '',
      });
    };

    return (
      <div className="messagecomposer">
        <Textarea
          className="crayons-textfield composer-textarea"
          id="messageform"
          placeholder="Write message..."
          onKeyDown={handleKeyDown}
          onKeyPress={handleMention}
          onKeyUp={handleKeyUp}
          onPaste={handleFilePaste}
          maxLength="1000"
          value={this.state.value}
          onInput={handleInput}
          aria-label="Compose a message"
        />
        <div>
          <button
            type="button"
            className="crayons-btn composer-submit"
            onClick={handleOnSubmitAction}
          >
            Send
          </button>
        </div>
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
