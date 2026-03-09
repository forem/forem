import { h, Component } from 'preact';

export class StepPreview extends Component {
  constructor(props) {
    super(props);
    this.state = {
      feedback: '',
      showConfirmOverwrite: false,
    };
  }

  handleIterate = (e) => {
    e.preventDefault();
    const { feedback } = this.state;
    if (feedback.trim()) {
      this.props.onIterate(feedback.trim());
      this.setState({ feedback: '' });
    }
  };

  handleSave = () => {
    if (this.props.hasExistingPage) {
      this.setState({ showConfirmOverwrite: true });
    } else {
      this.props.onSave();
    }
  };

  confirmSave = () => {
    this.setState({ showConfirmOverwrite: false });
    this.props.onSave();
  };

  render() {
    const { html, loading, onStartOver } = this.props;
    const { feedback, showConfirmOverwrite } = this.state;

    return (
      <div>
        <h2 className="fs-xl mb-4">Your new page</h2>

        <div className="crayons-card mb-4 p-4 overflow-auto" style={{ maxHeight: '600px' }}>
          {loading && (
            <div className="text-center py-4">
              <div className="crayons-indicator crayons-indicator--loading" />
              <p className="fs-s color-base-60 mt-2">Updating your page...</p>
            </div>
          )}
          <div
            className="crayons-article__body text-styles"
            dangerouslySetInnerHTML={{ __html: html }}
            style={{ opacity: loading ? 0.5 : 1 }}
          />
        </div>

        <form onSubmit={this.handleIterate} className="mb-4">
          <div className="flex gap-2">
            <input
              type="text"
              className="crayons-textfield flex-1"
              placeholder="Tell AI what to change..."
              value={feedback}
              onInput={(e) => this.setState({ feedback: e.target.value })}
              disabled={loading}
            />
            <button
              type="submit"
              className="crayons-btn crayons-btn--secondary"
              disabled={loading || !feedback.trim()}
            >
              Apply
            </button>
          </div>
        </form>

        {showConfirmOverwrite && (
          <div className="crayons-notice crayons-notice--warning mb-4">
            <p>Your org already has a page. This will replace it. Continue?</p>
            <div className="flex gap-2 mt-2">
              <button className="crayons-btn crayons-btn--s" onClick={this.confirmSave}>
                Yes, replace it
              </button>
              <button
                className="crayons-btn crayons-btn--ghost crayons-btn--s"
                onClick={() => this.setState({ showConfirmOverwrite: false })}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        <div className="flex gap-2">
          {!showConfirmOverwrite && (
            <button className="crayons-btn" onClick={this.handleSave} disabled={loading}>
              Looks good — Save Page
            </button>
          )}
          <button className="crayons-btn crayons-btn--ghost" onClick={onStartOver} disabled={loading}>
            Start Over
          </button>
        </div>
      </div>
    );
  }
}
