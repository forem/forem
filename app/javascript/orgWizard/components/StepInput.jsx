import { h, Component } from 'preact';

export class StepInput extends Component {
  constructor(props) {
    super(props);
    this.state = {
      urls: props.urls || [''],
    };
  }

  handleUrlChange = (index, value) => {
    const urls = [...this.state.urls];
    urls[index] = value;
    this.setState({ urls });
  };

  addUrl = () => {
    if (this.state.urls.length < 4) {
      this.setState({ urls: [...this.state.urls, ''] });
    }
  };

  removeUrl = (index) => {
    if (this.state.urls.length > 1) {
      const urls = this.state.urls.filter((_, i) => i !== index);
      this.setState({ urls });
    }
  };

  handleSubmit = (e) => {
    e.preventDefault();
    const validUrls = this.state.urls.filter((u) => u.trim());
    if (validUrls.length > 0) {
      this.props.onSubmit(validUrls);
    }
  };

  render() {
    const { loading } = this.props;
    const { urls } = this.state;

    if (loading) {
      return (
        <div className="text-center py-8">
          <div className="crayons-indicator crayons-indicator--loading" />
          <p className="fs-l mt-4 color-base-70">
            Learning about your organization...
          </p>
          <p className="fs-s color-base-60">
            Checking your site, searching DEV, detecting brand colors...
          </p>
        </div>
      );
    }

    return (
      <form onSubmit={this.handleSubmit}>
        <p className="color-base-70 mb-6">
          Share a link to your website or marketing page and we&apos;ll build
          you a beautiful org page using your content and what the DEV community
          has written about you.
        </p>

        {urls.map((url, index) => (
          <div key={index} className="flex items-center gap-2 mb-3">
            <input
              type="url"
              className="crayons-textfield flex-1"
              placeholder={
                index === 0
                  ? 'https://your-org.com'
                  : 'https://docs.your-org.com (optional)'
              }
              value={url}
              required={index === 0}
              onInput={(e) => this.handleUrlChange(index, e.target.value)}
            />
            {index > 0 && (
              <button
                type="button"
                className="crayons-btn crayons-btn--ghost crayons-btn--icon"
                onClick={() => this.removeUrl(index)}
                aria-label="Remove URL"
              >
                &times;
              </button>
            )}
          </div>
        ))}

        {urls.length < 4 && (
          <button
            type="button"
            className="crayons-btn crayons-btn--ghost fs-s mb-4"
            onClick={this.addUrl}
          >
            + Add another link
          </button>
        )}

        <div className="mt-6">
          <button type="submit" className="crayons-btn">
            Let&apos;s go
          </button>
        </div>
      </form>
    );
  }
}
