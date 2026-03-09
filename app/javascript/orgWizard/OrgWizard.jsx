import { h, Component } from 'preact';
import { StepInput } from './components/StepInput';
import { StepReview } from './components/StepReview';
// This will be created in Task 9:
// import { StepPreview } from './components/StepPreview';
import { request } from '@utilities/http';

export class OrgWizard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      step: 'input', // input | crawling | review | generating | preview | iterating | saving
      urls: [''],
      crawlData: null,
      selectedPosts: [],
      editedData: {},
      markdown: '',
      html: '',
      error: null,
    };
  }

  handleCrawl = async (urls) => {
    this.setState({ step: 'crawling', urls, error: null });
    try {
      const response = await request(this.props.crawlUrl, {
        method: 'POST',
        body: { urls },
      });
      if (!response.ok) throw new Error('Failed to crawl URLs');
      const data = await response.json();
      if (data.error && !data.title) {
        this.setState({ step: 'input', error: data.error });
        return;
      }
      const topPosts = (data.dev_posts || []).slice(0, 5).map((p) => p.id);
      this.setState({
        step: 'review',
        crawlData: data,
        selectedPosts: topPosts,
        editedData: {
          title: data.title || '',
          description: data.description || '',
          detected_color: data.detected_color || '',
        },
      });
    } catch (err) {
      this.setState({ step: 'input', error: err.message });
    }
  };

  handleGenerate = async () => {
    this.setState({ step: 'generating', error: null });
    const { editedData, crawlData, selectedPosts } = this.state;
    const devPosts = (crawlData.dev_posts || []).filter((p) =>
      selectedPosts.includes(p.id),
    );
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
      this.setState({ step: 'review', error: err.message });
    }
  };

  handleIterate = async (instruction) => {
    this.setState({ step: 'iterating', error: null });
    const { editedData, crawlData, selectedPosts, markdown } = this.state;
    const devPosts = (crawlData.dev_posts || []).filter((p) =>
      selectedPosts.includes(p.id),
    );
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

  render() {
    const { organization } = this.props;
    const { step, error } = this.state;

    return (
      <div
        className="org-wizard crayons-card p-6 m-auto"
        style={{ maxWidth: '800px' }}
      >
        <h1 className="fs-2xl mb-2">
          Setting up {organization.name}&apos;s page
        </h1>

        {error && (
          <div
            className="crayons-notice crayons-notice--danger mb-4"
            role="alert"
          >
            {error}
          </div>
        )}

        {(step === 'input' || step === 'crawling') && (
          <StepInput
            urls={this.state.urls}
            loading={step === 'crawling'}
            onSubmit={this.handleCrawl}
          />
        )}

        {/* StepPreview will be added in Task 9 */}
        {(step === 'review' || step === 'generating') && (
          <StepReview
            crawlData={this.state.crawlData}
            editedData={this.state.editedData}
            selectedPosts={this.state.selectedPosts}
            loading={step === 'generating'}
            onEditData={(editedData) => this.setState({ editedData })}
            onTogglePost={(postId) => {
              const { selectedPosts } = this.state;
              const updated = selectedPosts.includes(postId)
                ? selectedPosts.filter((id) => id !== postId)
                : [...selectedPosts, postId];
              this.setState({ selectedPosts: updated });
            }}
            onGenerate={this.handleGenerate}
            onBack={this.handleStartOver}
          />
        )}

        {(step === 'preview' || step === 'iterating' || step === 'saving') && (
          <div className="text-center py-8">
            <p>Step 3 component coming soon (Task 9)</p>
          </div>
        )}
      </div>
    );
  }
}
