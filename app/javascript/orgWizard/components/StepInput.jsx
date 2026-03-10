import { h, Component } from 'preact';

const PAGE_TYPES = [
  {
    value: 'developer',
    label: 'Developer-Focused',
    description: 'Docs, APIs, code samples, and technical resources',
    fields: [
      { label: 'Developer landing page', placeholder: 'https://your-org.com/developers' },
      { label: 'Documentation', placeholder: 'https://docs.your-org.com' },
      { label: 'GitHub', placeholder: 'https://github.com/your-org' },
      { label: 'YouTube', placeholder: 'https://youtube.com/@your-org' },
    ],
  },
  {
    value: 'marketing',
    label: 'Marketing Showcase',
    description: 'Product highlights, testimonials, and calls-to-action',
    fields: [
      { label: 'Homepage', placeholder: 'https://your-org.com' },
      { label: 'Customers or case studies', placeholder: 'https://your-org.com/customers' },
      { label: 'Pricing', placeholder: 'https://your-org.com/pricing' },
      { label: 'YouTube', placeholder: 'https://youtube.com/@your-org' },
    ],
  },
  {
    value: 'community',
    label: 'Community Hub',
    description: 'Team members, DEV posts, and community engagement',
    fields: [
      { label: 'Community page', placeholder: 'https://your-org.com/community' },
      { label: 'Blog', placeholder: 'https://your-org.com/blog' },
      { label: 'GitHub', placeholder: 'https://github.com/your-org' },
      { label: 'Discord or forum', placeholder: 'https://discord.gg/your-org' },
    ],
  },
  {
    value: 'talent',
    label: 'Talent & Careers',
    description: 'Team culture, open roles, and why developers should join',
    fields: [
      { label: 'Careers page', placeholder: 'https://your-org.com/careers' },
      { label: 'About us', placeholder: 'https://your-org.com/about' },
      { label: 'Engineering blog', placeholder: 'https://your-org.com/engineering-blog' },
      { label: 'YouTube', placeholder: 'https://youtube.com/@your-org' },
    ],
  },
];

export class StepInput extends Component {
  constructor(props) {
    super(props);
    this.state = {
      urls: ['', '', '', ''],
      otherUrl: '',
      pageType: 'developer',
    };
  }

  handleUrlChange = (index, value) => {
    const urls = [...this.state.urls];
    urls[index] = value;
    this.setState({ urls });
  };

  handleSubmit = (e) => {
    e.preventDefault();
    const allUrls = [...this.state.urls, this.state.otherUrl];
    const validUrls = allUrls.filter((u) => u.trim());
    if (validUrls.length > 0) {
      this.props.onSubmit(validUrls, this.state.pageType);
    }
  };

  render() {
    const { urls, pageType } = this.state;

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
                onClick={() => this.setState({ pageType: pt.value, urls: ['', '', '', ''], otherUrl: '' })}
              >
                <span className="fw-bold fs-s">{pt.label}</span>
                <p className="fs-xs color-base-60 mt-1 mb-0">{pt.description}</p>
              </button>
            ))}
          </div>
        </div>

        {(() => {
          const currentType = PAGE_TYPES.find((pt) => pt.value === pageType);
          const placeholders = currentType?.fields.map((f) => f.placeholder) || [];
          return [...placeholders, 'https://any-other-relevant-link.com'].map((ph, index) => (
            <div key={`${pageType}-${index}`} className="mb-3">
              <input
                type="url"
                className="crayons-textfield"
                placeholder={ph}
                value={index < 4 ? (urls[index] || '') : this.state.otherUrl}
                required={index === 0}
                onInput={(e) => {
                  if (index < 4) {
                    this.handleUrlChange(index, e.target.value);
                  } else {
                    this.setState({ otherUrl: e.target.value });
                  }
                }}
              />
            </div>
          ));
        })()}

        <div className="mt-6">
          <button type="submit" className="crayons-btn">
            Let&apos;s go
          </button>
        </div>
      </form>
    );
  }
}
