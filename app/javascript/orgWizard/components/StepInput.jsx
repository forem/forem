import { h, Component } from 'preact';

const PAGE_TYPES = [
  { value: 'developer', label: 'Developer-Focused', description: 'Docs, APIs, code samples, and technical resources' },
  { value: 'marketing', label: 'Marketing Showcase', description: 'Product highlights, testimonials, and calls-to-action' },
  { value: 'community', label: 'Community Hub', description: 'Team members, DEV posts, and community engagement' },
  { value: 'talent', label: 'Talent & Careers', description: 'Team culture, open roles, and why developers should join' },
];

export class StepInput extends Component {
  constructor(props) {
    super(props);
    this.state = {
      urls: props.urls || [''],
      pageType: 'developer',
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
      this.props.onSubmit(validUrls, this.state.pageType);
    }
  };

  render() {
    const { loading } = this.props;
    const { urls, pageType } = this.state;

    const loadingMessages = {
      developer: 'Searching for developer resources, APIs, and docs...',
      marketing: 'Analyzing your product and brand positioning...',
      community: 'Finding community content and team members...',
      talent: 'Learning about your team culture and values...',
    };

    if (loading) {
      return (
        <div className="text-center py-8">
          <div className="crayons-indicator crayons-indicator--loading" />
          <p className="fs-l mt-4 color-base-70">
            Learning about your organization...
          </p>
          <p className="fs-s color-base-60">
            {loadingMessages[pageType] || 'Checking your site, searching DEV, detecting brand colors...'}
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

        <div className="mb-6">
          <h3 className="fs-l mb-2">What kind of page do you want?</h3>
          <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(2, 1fr)' }}>
            {PAGE_TYPES.map((pt) => (
              <button
                key={pt.value}
                type="button"
                className={`crayons-card p-3 text-left cursor-pointer`}
                style={{
                  border: pageType === pt.value ? '2px solid var(--accent-brand)' : '1px solid var(--base-20)',
                }}
                onClick={() => this.setState({ pageType: pt.value })}
              >
                <span className="fw-bold fs-s">{pt.label}</span>
                <p className="fs-xs color-base-60 mt-1 mb-0">{pt.description}</p>
              </button>
            ))}
          </div>
        </div>

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
