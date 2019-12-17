import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export default class Chat extends Component {
  static propTypes = {
    handleKeyDown: PropTypes.func.isRequired,
    handleKeyDownEdit: PropTypes.func.isRequired,
    handleSubmitOnClick: PropTypes.func.isRequired,
    handleSubmitOnClickEdit: PropTypes.func.isRequired,
    startEditing: PropTypes.bool.isRequired,
    editMessageHtml: PropTypes.string.isRequired,
    editMessageMarkdown: PropTypes.string.isRequired,
    handleEditMessageClose: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      editMessageMarkdown: null,
    };
  }

  componentWillReceiveProps(props) {
    this.setState({
      editMessageMarkdown: props.editMessageMarkdown,
      editMessageHtml: props.editMessageHtml,
    });
  }

  messageCompose = () => {
    const {
      handleSubmitOnClickEdit,
      handleKeyDownEdit,
      handleEditMessageClose,
    } = this.props;
    const { editMessageHtml, editMessageMarkdown } = this.state;
    return (
      <div className="messagecomposer">
        <div className="messageToBeEdited">
          <div className="message">
            <span className="editHead">Edit Message</span>
            <div
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
          maxLength="1000"
          value={editMessageMarkdown}
        />
        <button
          type="button"
          className="messagecomposer__submit"
          onClick={handleSubmitOnClickEdit}
        >
          Save
        </button>
      </div>
    );
  };

  render() {
    const { handleSubmitOnClick, handleKeyDown, startEditing } = this.props;
    return (
      <div>
        {!startEditing ? (
          <div className="messagecomposer">
            <textarea
              className="messagecomposer__input"
              id="messageform"
              placeholder="Message goes here"
              onKeyDown={handleKeyDown}
              maxLength="1000"
            />
            <button
              type="button"
              className="messagecomposer__submit"
              onClick={handleSubmitOnClick}
            >
              SEND
            </button>
          </div>
        ) : (
          this.messageCompose()
        )}
      </div>
    );
  }
}
