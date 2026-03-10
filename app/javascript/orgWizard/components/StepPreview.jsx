import { h, Component } from 'preact';
import { LoadingSteps } from './LoadingSteps';
import { EditorBody } from '../../article-form/components/EditorBody';
import { request } from '@utilities/http';

const ITERATE_STEPS = [
  { label: 'Reading your feedback...', icon: '💬' },
  { label: 'Reviewing the current page...', icon: '📋' },
  { label: 'Planning the changes...', icon: '🧠' },
  { label: 'Rewriting sections...', icon: '✍️' },
  { label: 'Validating liquid tag syntax...', icon: '🔧' },
  { label: 'Polishing the result...', icon: '✨' },
];

const TEXTAREA_ID = 'org_wizard_markdown';

export class StepPreview extends Component {
  constructor(props) {
    super(props);
    this.state = {
      feedback: '',
      showConfirmOverwrite: false,
      showEditor: true,
      previewHtml: props.html || '',
      rendering: false,
      dirty: false,
      editorKey: 0,
    };
    this._renderTimer = null;
    this._latestMarkdown = props.markdown || '';
  }

  componentDidUpdate(prevProps) {
    if (prevProps.markdown !== this.props.markdown) {
      this._latestMarkdown = this.props.markdown;
      this.setState({
        previewHtml: this.props.html,
        dirty: false,
        editorKey: this.state.editorKey + 1,
      });
    }
  }

  componentWillUnmount() {
    if (this._renderTimer) clearTimeout(this._renderTimer);
  }

  handleEditorChange = (e) => {
    const value = e.target.value;
    this._latestMarkdown = value;
    this.setState({ dirty: true });

    if (this._renderTimer) clearTimeout(this._renderTimer);
    this._renderTimer = setTimeout(() => this.renderPreview(value), 800);
  };

  renderPreview = async (markdown) => {
    this.setState({ rendering: true });
    try {
      const response = await request(this.props.previewUrl, {
        method: 'POST',
        body: { markdown },
      });
      const data = await response.json();
      this.setState({ previewHtml: data.html, rendering: false });
    } catch {
      this.setState({ rendering: false });
    }
  };

  applyEdits = () => {
    const { previewHtml } = this.state;
    this.props.onMarkdownChange(this._latestMarkdown, previewHtml);
    this.setState({ dirty: false });
  };

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
    const { html, markdown, loading, onStartOver, brandColor } = this.props;
    const { feedback, showConfirmOverwrite, showEditor, previewHtml, rendering, dirty, editorKey } = this.state;

    if (loading) {
      return <LoadingSteps steps={ITERATE_STEPS} />;
    }

    const displayHtml = showEditor ? previewHtml : html;

    return (
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="fs-xl mb-0">Your new page</h2>
          <div className="flex items-center gap-2">
            {showEditor && rendering && (
              <span className="fs-xs color-base-50">Rendering...</span>
            )}
            {showEditor && dirty && (
              <button
                type="button"
                className="crayons-btn crayons-btn--s"
                onClick={this.applyEdits}
              >
                Apply Edits
              </button>
            )}
            <button
              type="button"
              className="crayons-btn crayons-btn--ghost crayons-btn--s"
              onClick={() => this.setState({ showEditor: !showEditor })}
            >
              {showEditor ? 'Hide Editor' : 'Edit Markdown'}
            </button>
          </div>
        </div>

        {showEditor ? (
          <div className="flex gap-4 mb-4" style={{ minHeight: '500px' }}>
            {/* Markdown editor */}
            <div className="flex-1 flex flex-col" style={{ minWidth: 0 }}>
              <span className="fs-s fw-medium color-base-70 mb-2">Markdown</span>
              <div
                className="crayons-card overflow-hidden flex-1"
                style={{ minHeight: '480px' }}
              >
                <EditorBody
                  key={editorKey}
                  defaultValue={markdown}
                  onChange={this.handleEditorChange}
                  textAreaId={TEXTAREA_ID}
                  textAreaName="wizard_markdown"
                  placeholder="Your org page markdown..."
                  ariaLabel="Page content"
                  className="crayons-textfield crayons-textfield--ghost ff-monospace fs-s"
                  version="v2"
                />
              </div>
            </div>

            {/* Preview */}
            <div className="flex-1 flex flex-col" style={{ minWidth: 0 }}>
              <span className="fs-s fw-medium color-base-70 mb-2">Preview</span>
              <div
                className="crayons-card p-4 overflow-auto flex-1"
                style={{
                  minHeight: '480px',
                  maxHeight: '600px',
                  ...(brandColor ? { '--accent-brand': brandColor } : {}),
                }}
              >
                <div
                  className="crayons-article__body text-styles"
                  dangerouslySetInnerHTML={{ __html: displayHtml }}
                />
              </div>
            </div>
          </div>
        ) : (
          <div
            className="crayons-card mb-4 p-4 overflow-auto"
            style={{
              maxHeight: '600px',
              ...(brandColor ? { '--accent-brand': brandColor } : {}),
            }}
          >
            <div
              className="crayons-article__body text-styles"
              dangerouslySetInnerHTML={{ __html: displayHtml }}
            />
          </div>
        )}

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
              <button type="button" className="crayons-btn crayons-btn--s" onClick={this.confirmSave}>
                Yes, replace it
              </button>
              <button
                type="button"
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
            <button type="button" className="crayons-btn" onClick={this.handleSave} disabled={loading}>
              Looks good — Save Page
            </button>
          )}
          <button type="button" className="crayons-btn crayons-btn--secondary" onClick={this.props.onRegenerate} disabled={loading}>
            Regenerate
          </button>
          <button type="button" className="crayons-btn crayons-btn--ghost" onClick={onStartOver} disabled={loading}>
            Start Over
          </button>
        </div>
      </div>
    );
  }
}
