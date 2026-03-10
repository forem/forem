import { h, Component, Fragment } from 'preact';
import { StepInput } from './components/StepInput';
import { StepPreview } from './components/StepPreview';
import { LoadingSteps } from './components/LoadingSteps';
import { request } from '@utilities/http';

function buildProgressSteps(pageType) {
  const extractLabel =
    pageType === 'developer' ? 'Identifying APIs, SDKs, and dev tools...'
    : pageType === 'marketing' ? 'Analyzing product positioning...'
    : pageType === 'community' ? 'Finding community highlights...'
    : pageType === 'talent' ? 'Understanding team culture...'
    : 'Analyzing page content...';

  return [
    { label: 'Crawling your links...', icon: '🌐' },
    { label: 'Reading page content...', icon: '📄' },
    { label: extractLabel, icon: '🔍' },
    { label: 'Searching DEV for related posts...', icon: '📝' },
    { label: 'Choosing the best page layout...', icon: '🏗️' },
    { label: 'Writing headlines and descriptions...', icon: '✍️' },
    { label: 'Building feature cards...', icon: '🃏' },
    { label: 'Styling with your brand colors...', icon: '🎨' },
    { label: 'Validating liquid tag syntax...', icon: '🔧' },
    { label: 'Final polish...', icon: '✨' },
  ];
}

const STEP_LABELS = ['Customize', 'Review', 'Publish'];

export class OrgWizard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      step: 'input', // input | crawling | generating | preview | iterating | saving
      urls: [''],
      crawlData: null,
      selectedPosts: [],
      editedData: {},
      markdown: '',
      html: '',
      error: null,
    };
  }

  handleCrawl = async (urls, pageType) => {
    this.setState({ step: 'crawling', urls, pageType, error: null });
    try {
      const response = await request(this.props.crawlUrl, {
        method: 'POST',
        body: { urls, page_type: pageType },
      });
      if (!response.ok) throw new Error('Failed to crawl URLs');
      const data = await response.json();
      if (data.error && !data.title) {
        this.setState({ step: 'input', error: data.error });
        return;
      }
      const topPosts = (data.dev_posts || []).slice(0, 5).map((p) => p.id);
      const editedData = {
        title: data.title || '',
        description: data.description || '',
        detected_color: data.detected_color || '',
        og_image: data.og_image || '',
        page_type: pageType || 'developer',
        features: data.features || [],
        testimonials: data.testimonials || [],
        dev_comments: data.dev_comments || [],
        youtube_urls: data.youtube_urls || [],
        content_images: data.content_images || [],
      };
      this.setState({ crawlData: data, selectedPosts: topPosts, editedData }, () => {
        this.handleGenerate();
      });
    } catch (err) {
      this.setState({ step: 'input', error: err.message });
    }
  };

  getSelectedDevPosts() {
    const { crawlData, selectedPosts } = this.state;
    return (crawlData.dev_posts || []).filter((p) => selectedPosts.includes(p.id));
  }

  handleGenerate = async () => {
    this.setState({ step: 'generating', error: null });
    const { editedData, crawlData } = this.state;
    const devPosts = this.getSelectedDevPosts();
    try {
      const response = await request(this.props.generateUrl, {
        method: 'POST',
        body: {
          org_data: { ...editedData, links: crawlData.links || [] },
          dev_posts: devPosts,
        },
      });
      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Generation failed');
      }
      const result = await response.json();
      this.setState({
        step: 'preview',
        markdown: result.markdown,
        html: result.html,
      });
    } catch (err) {
      this.setState({ step: 'input', error: err.message });
    }
  };

  handleIterate = async (instruction) => {
    this.setState({ step: 'iterating', error: null });
    const { editedData, crawlData, markdown } = this.state;
    const devPosts = this.getSelectedDevPosts();
    try {
      const response = await request(this.props.iterateUrl, {
        method: 'POST',
        body: {
          current_markdown: markdown,
          instruction,
          org_data: { ...editedData, links: crawlData.links || [] },
          dev_posts: devPosts,
        },
      });
      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Iteration failed');
      }
      const result = await response.json();
      this.setState({
        step: 'preview',
        markdown: result.markdown,
        html: result.html,
      });
    } catch (err) {
      this.setState({ step: 'preview', error: err.message });
    }
  };

  handleSave = async () => {
    this.setState({ step: 'saving', error: null });
    try {
      const response = await request(this.props.saveUrl, {
        method: 'POST',
        body: {
          markdown: this.state.markdown,
          detected_color: this.state.editedData.detected_color,
          og_image: this.state.editedData.og_image,
          urls: this.state.urls,
        },
      });
      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Save failed');
      }
      const result = await response.json();
      window.location.href = result.redirect_url;
    } catch (err) {
      this.setState({ step: 'preview', error: err.message });
    }
  };

  handleStartOver = () => {
    this.setState({
      step: 'input',
      urls: [''],
      crawlData: null,
      selectedPosts: [],
      editedData: {},
      markdown: '',
      html: '',
      error: null,
    });
  };

  stepNumber() {
    const { step } = this.state;
    if (step === 'input' || step === 'crawling' || step === 'generating') return 1;
    if (step === 'preview' || step === 'iterating') return 2;
    return 3;
  }

  render() {
    const { organization, settingsUrl } = this.props;
    const { step, error } = this.state;
    const isNewOrg = organization.new_org;
    const currentStepNum = this.stepNumber();
    const stepLabels = STEP_LABELS;
    const isLoading = ['crawling', 'generating', 'iterating', 'saving'].includes(step);

    const isPreviewStep = ['preview', 'iterating', 'saving'].includes(step);

    return (
      <div
        className="org-wizard crayons-card p-6 m-auto"
        style={{ maxWidth: isPreviewStep ? '1200px' : '800px', transition: 'max-width 0.3s ease' }}
      >
        <div className="flex items-center justify-between mb-2">
          <h1 className="fs-2xl mb-0">
            {isNewOrg ? `Welcome to ${organization.name}!` : `${organization.name}'s page`}
          </h1>
          <a
            href={settingsUrl}
            className="fs-s color-base-60"
          >
            {isNewOrg ? 'Skip to settings' : 'Back to settings'}
          </a>
        </div>

        {isNewOrg && currentStepNum === 1 && !isLoading && (
          <p className="color-base-60 mb-4 fs-s">
            Your organization is live! Let&apos;s create a page that shows the DEV community what you&apos;re all about.
          </p>
        )}

        {/* Step indicator */}
        <div className="flex items-center gap-2 mb-6" style={{ maxWidth: '360px' }}>
          {stepLabels.map((label, idx) => {
            const num = idx + 1;
            const isActive = num === currentStepNum;
            const isDone = num < currentStepNum;
            return (
              <Fragment key={num}>
                <div className="flex items-center gap-2">
                  <div
                    className={`flex items-center justify-center fw-bold fs-xs ${
                      isActive ? 'color-base-inverted' : isDone ? 'color-base-inverted' : 'color-base-50'
                    }`}
                    style={{
                      width: '24px',
                      height: '24px',
                      borderRadius: '50%',
                      backgroundColor: isActive
                        ? 'var(--accent-brand)'
                        : isDone
                          ? 'var(--base-60)'
                          : 'var(--base-10)',
                      flexShrink: 0,
                    }}
                  >
                    {isDone ? '\u2713' : num}
                  </div>
                  <span className={`fs-xs ${isActive ? 'fw-medium color-base-90' : 'color-base-50'}`}>
                    {label}
                  </span>
                </div>
                {idx < stepLabels.length - 1 && (
                  <div
                    style={{
                      height: '1px',
                      flex: 1,
                      backgroundColor: isDone ? 'var(--base-60)' : 'var(--base-10)',
                    }}
                  />
                )}
              </Fragment>
            );
          })}
        </div>

        {error && (
          <div
            className="crayons-notice crayons-notice--danger mb-4"
            role="alert"
          >
            {error}
          </div>
        )}

        {step === 'input' && (
          <StepInput
            onSubmit={this.handleCrawl}
          />
        )}

        {(step === 'crawling' || step === 'generating') && (
          <LoadingSteps steps={buildProgressSteps(this.state.pageType)} />
        )}

        {(step === 'preview' || step === 'iterating' || step === 'saving') && (
          <StepPreview
            html={this.state.html}
            markdown={this.state.markdown}
            loading={step === 'iterating' || step === 'saving'}
            brandColor={this.state.editedData.detected_color}
            previewUrl={this.props.previewUrl}
            onIterate={this.handleIterate}
            onMarkdownChange={(markdown, html) => this.setState({ markdown, html })}
            onRegenerate={this.handleGenerate}
            onSave={this.handleSave}
            onStartOver={this.handleStartOver}
            hasExistingPage={organization.has_page}
          />
        )}
      </div>
    );
  }
}
