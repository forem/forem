import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkState from 'linkstate';
import postscribe from 'postscribe';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { submitArticle, previewArticle } from './actions';
import { EditorActions, Form, Header, Help, Preview } from './components';
import { Button, Modal } from '@crayons';

/* global activateRunkitTags */

/*
  Although the state fields: id, description, canonicalUrl, series, allSeries and
  editing are not used in this file, they are important to the
  editor.
*/
export class ArticleForm extends Component {
  static handleGistPreview() {
    const els = document.getElementsByClassName('ltag_gist-liquid-tag');
    for (let i = 0; i < els.length; i += 1) {
      postscribe(els[i], els[i].firstElementChild.outerHTML);
    }
  }

  static handleRunkitPreview() {
    activateRunkitTags();
  }

  // Scripts inserted via innerHTML won't execute, so we use this handler to
  // make the Asciinema player work in previews.
  static handleAsciinemaPreview() {
    const els = document.getElementsByClassName('ltag_asciinema');
    for (let i = 0; i < els.length; i += 1) {
      const el = els[i];
      const script = el.removeChild(el.firstElementChild);
      postscribe(el, script.outerHTML);
    }
  }

  static propTypes = {
    version: PropTypes.string.isRequired,
    article: PropTypes.string.isRequired,
    organizations: PropTypes.string,
    siteLogo: PropTypes.string.isRequired,
  };

  static defaultProps = {
    organizations: '',
  };

  constructor(props) {
    super(props);
    const { article, version, siteLogo } = this.props;
    let { organizations } = this.props;
    this.article = JSON.parse(article);
    organizations = organizations ? JSON.parse(organizations) : null;
    this.url = window.location.href;

    const previousContent =
      JSON.parse(
        localStorage.getItem(`editor-${version}-${window.location.href}`),
      ) || {};
    const isLocalstorageNewer =
      new Date(previousContent.updatedAt) > new Date(this.article.updated_at);

    const previousContentState =
      previousContent && isLocalstorageNewer
        ? {
            title: previousContent.title || '',
            tagList: previousContent.tagList || '',
            mainImage: previousContent.mainImage || null,
            bodyMarkdown: previousContent.bodyMarkdown || '',
            edited: true,
          }
        : {};

    this.state = {
      id: this.article.id || null, // eslint-disable-line react/no-unused-state
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '', // eslint-disable-line react/no-unused-state
      canonicalUrl: this.article.canonical_url || '', // eslint-disable-line react/no-unused-state
      series: this.article.series || '', // eslint-disable-line react/no-unused-state
      allSeries: this.article.all_series || [], // eslint-disable-line react/no-unused-state
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      previewResponse: '',
      submitting: false,
      editing: this.article.id !== null, // eslint-disable-line react/no-unused-state
      mainImage: this.article.main_image || null,
      organizations,
      organizationId: this.article.organization_id,
      errors: null,
      edited: false,
      updatedAt: this.article.updated_at,
      version,
      siteLogo,
      helpFor: null,
      helpPosition: null,
      ...previousContentState,
    };
  }

  componentDidMount() {
    window.addEventListener('beforeunload', this.localStoreContent);
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.localStoreContent);
  }

  componentDidUpdate() {
    const { previewResponse } = this.state;

    if (previewResponse) {
      this.constructor.handleGistPreview();
      this.constructor.handleRunkitPreview();
      this.constructor.handleAsciinemaPreview();
    }
  }

  localStoreContent = () => {
    const { version, title, tagList, mainImage, bodyMarkdown } = this.state;
    const updatedAt = new Date();
    localStorage.setItem(
      `editor-${version}-${this.url}`,
      JSON.stringify({
        title,
        tagList,
        mainImage,
        bodyMarkdown,
        updatedAt,
      }),
    );
  };

  setCommonProps = ({
    previewShowing = false,
    helpFor = null,
    helpPosition = null,
  }) => {
    return {
      previewShowing,
      helpFor,
      helpPosition,
    };
  };

  fetchPreview = (e) => {
    const { previewShowing, bodyMarkdown } = this.state;
    e.preventDefault();
    if (previewShowing) {
      this.setState({
        ...this.setCommonProps({}),
      });
    } else {
      previewArticle(bodyMarkdown, this.showPreview, this.failedPreview);
    }
  };

  showPreview = (response) => {
    this.setState({
      ...this.setCommonProps({ previewShowing: true }),
      previewResponse: response,
      errors: null,
    });
  };

  handleOrgIdChange = (e) => {
    const organizationId = e.target.selectedOptions[0].value;
    this.setState({ organizationId });
  };

  failedPreview = (response) => {
    this.setState({
      errors: response,
      submitting: false,
    });
  };

  handleConfigChange = (e) => {
    e.preventDefault();
    const newState = {};
    newState[e.target.name] = e.target.value;
    this.setState(newState);
  };

  handleMainImageUrlChange = (payload) => {
    this.setState({
      mainImage: payload.links[0],
    });
  };

  removeLocalStorage = () => {
    const { version } = this.state;
    localStorage.removeItem(`editor-${version}-${this.url}`);
    window.removeEventListener('beforeunload', this.localStoreContent);
  };

  onPublish = (e) => {
    e.preventDefault();
    this.setState({ submitting: true, published: true });
    const { state } = this;
    state.published = true;
    submitArticle(state, this.removeLocalStorage, this.handleArticleError);
  };

  onSaveDraft = (e) => {
    e.preventDefault();
    this.setState({ submitting: true, published: false });
    const { state } = this;
    state.published = false;
    submitArticle(state, this.removeLocalStorage, this.handleArticleError);
  };

  onClearChanges = (e) => {
    e.preventDefault();
    // eslint-disable-next-line no-alert
    const revert = window.confirm(
      'Are you sure you want to revert to the previous save?',
    );
    if (!revert && navigator.userAgent !== 'DEV-Native-ios') return;

    this.setState({
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '', // eslint-disable-line react/no-unused-state
      canonicalUrl: this.article.canonical_url || '', // eslint-disable-line react/no-unused-state
      series: this.article.series || '', // eslint-disable-line react/no-unused-state
      allSeries: this.article.all_series || [], // eslint-disable-line react/no-unused-state
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      previewResponse: '',
      submitting: false,
      editing: this.article.id !== null, // eslint-disable-line react/no-unused-state
      mainImage: this.article.main_image || null,
      errors: null,
      edited: false,
      helpFor: null,
      helpPosition: 0,
      showModal: false,
    });
  };

  handleArticleError = (response, publishFailed = false) => {
    window.scrollTo(0, 0);
    const { published } = this.state;
    this.setState({
      errors: response,
      submitting: false,
      // Even if it's an update that failed, published will still be set to true
      published: published && !publishFailed,
    });
  };

  toggleEdit = () => {
    this.localStoreContent();
    const { edited } = this.state;
    if (edited) return;
    this.setState({
      edited: true,
    });
  };

  toggleModal = () => {
    if (this.state.edited) {
      this.setState({
        showModal: !this.state.showModal,
      });
    } else {
      // If the user has not edited the body we send them home
      window.location.href = '/';
    }
  };

  switchHelpContext = ({ target }) => {
    this.setState({
      ...this.setCommonProps({
        helpFor: target.id,
        helpPosition: target.getBoundingClientRect().y,
      }),
    });
  };

  render() {
    const {
      title,
      tagList,
      bodyMarkdown,
      published,
      previewShowing,
      previewResponse,
      submitting,
      organizations,
      organizationId,
      mainImage,
      errors,
      edited,
      version,
      helpFor,
      helpPosition,
      siteLogo,
    } = this.state;

    return (
      <form
        id="article-form"
        className="crayons-article-form"
        onSubmit={this.onSubmit}
        onInput={this.toggleEdit}
        data-testid="article-form"
      >
        <Header
          onPreview={this.fetchPreview}
          previewShowing={previewShowing}
          organizations={organizations}
          organizationId={organizationId}
          onToggle={this.handleOrgIdChange}
          siteLogo={siteLogo}
          displayModal={this.toggleModal}
        />

        {previewShowing ? (
          <Preview
            previewResponse={previewResponse}
            articleState={this.state}
            errors={errors}
          />
        ) : (
          <Form
            titleDefaultValue={title}
            titleOnChange={linkState(this, 'title')}
            tagsDefaultValue={tagList}
            tagsOnInput={linkState(this, 'tagList')}
            bodyDefaultValue={bodyMarkdown}
            bodyOnChange={linkState(this, 'bodyMarkdown')}
            bodyHasFocus={false}
            version={version}
            mainImage={mainImage}
            onMainImageUrlChange={this.handleMainImageUrlChange}
            errors={errors}
            switchHelpContext={this.switchHelpContext}
          />
        )}

        <Help
          previewShowing={previewShowing}
          helpFor={helpFor}
          helpPosition={helpPosition}
          version={version}
        />
        {this.state.showModal && (
          <Modal
            size="s"
            title="You have unsaved changes"
            onClose={this.toggleModal}
          >
            <p>
              You've made changes to your post. Do you want to navigate to leave
              this page?
            </p>
            <div className="pt-4">
              <Button className="mr-2" variant="danger" url="/" tagName="a">
                Yes, leave the page
              </Button>
              <Button variant="secondary" onClick={this.toggleModal}>
                No, keep editing
              </Button>
            </div>
          </Modal>
        )}

        <EditorActions
          published={published}
          version={version}
          onPublish={this.onPublish}
          onSaveDraft={this.onSaveDraft}
          onClearChanges={this.onClearChanges}
          edited={edited}
          passedData={this.state}
          onConfigChange={this.handleConfigChange}
          submitting={submitting}
        />

        <KeyboardShortcuts
          shortcuts={{
            'ctrl+shift+KeyP': this.fetchPreview,
          }}
        />
      </form>
    );
  }
}
