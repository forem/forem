import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkState from 'linkstate';
import postscribe from 'postscribe';
import moment from 'moment';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { embedGists } from '../utilities/gist';
import { submitArticle, previewArticle } from './actions';
import { EditorActions, Form, Header, Help, Preview } from './components';
import { Button, Modal } from '@crayons';
import {
  noDefaultAltTextRule,
  noEmptyAltTextRule,
  noLevelOneHeadingsRule,
  headingIncrement,
} from '@utilities/markdown/markdownLintCustomRules';
import { getOSKeyboardModifierKeyString } from '@utilities/runtime';

/* global activateRunkitTags */

/*
  Although the state fields: id, description, canonicalUrl, publishedAtDate, publishedAtTime, series, allSeries and
  editing are not used in this file, they are important to the
  editor.
*/

/**
 * Settings for the markdownlint library we use to identify potential accessibility failings in posts
 */
const LINT_OPTIONS = {
  customRules: [
    noDefaultAltTextRule,
    noLevelOneHeadingsRule,
    headingIncrement,
    noEmptyAltTextRule,
  ],
  config: {
    default: false, // disable all default rules
    [noDefaultAltTextRule.names[0]]: true,
    [noLevelOneHeadingsRule.names[0]]: true,
    [headingIncrement.names[0]]: true,
    [noEmptyAltTextRule.names[0]]: true,
  },
};

export class ArticleForm extends Component {
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
    schedulingEnabled: PropTypes.bool.isRequired,
  };

  static defaultProps = {
    organizations: '[]',
  };

  constructor(props) {
    super(props);
    const { article, version, siteLogo, schedulingEnabled } = this.props;
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

    this.publishedAtTime = '';
    this.publishedAtDate = '';
    this.publishedAtWas = '';

    if (this.article.published_at) {
      this.publishedAtWas = moment(this.article.published_at);
      this.publishedAtTime = this.publishedAtWas.format('HH:mm');
      this.publishedAtDate = this.publishedAtWas.format('YYYY-MM-DD');
    }

    this.state = {
      formKey: new Date().toISOString(),
      id: this.article.id || null, // eslint-disable-line react/no-unused-state
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '', // eslint-disable-line react/no-unused-state
      canonicalUrl: this.article.canonical_url || '', // eslint-disable-line react/no-unused-state
      publishedAtTime: this.publishedAtTime,
      publishedAtDate: this.publishedAtDate,
      publishedAtWas: this.publishedAtWas,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || '', // eslint-disable-line react/no-unused-state
      series: this.article.series || '', // eslint-disable-line react/no-unused-state
      allSeries: this.article.all_series || [], // eslint-disable-line react/no-unused-state
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      schedulingEnabled,
      previewShowing: false,
      previewLoading: false,
      previewResponse: { processed_html: '' },
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
      isModalOpen: false,
      markdownLintErrors: [],
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

    if (previewResponse?.processed_html) {
      embedGists(this.formElement);
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
    previewLoading = false,
    helpFor = null,
    helpPosition = null,
  }) => {
    return {
      previewShowing,
      previewLoading,
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
      this.showLoadingPreview();
      previewArticle(bodyMarkdown, this.showPreview, this.failedPreview);
    }
  };

  lintMarkdown = () => {
    const options = {
      ...LINT_OPTIONS,
      strings: {
        content: this.state.bodyMarkdown,
      },
    };
    const { content: markdownLintErrors } = window.markdownlint.sync(options);
    this.setState({ markdownLintErrors });
  };

  fetchMarkdownLint = async () => {
    if (!window.markdownlint) {
      const pathDataElement = document.getElementById('markdown-lint-js-path');
      if (!pathDataElement) {
        return;
      }

      // Retrieve the correct fingerprinted URL for the scripts
      const { markdownItJsPath, markdownLintJsPath } = pathDataElement.dataset;

      const markdownItScript = document.createElement('script');
      markdownItScript.setAttribute('src', markdownItJsPath);
      document.body.appendChild(markdownItScript);

      // The markdownlint script needs the first script to have finished loading first
      markdownItScript.addEventListener('load', () => {
        const markdownLintScript = document.createElement('script');
        markdownLintScript.setAttribute('src', markdownLintJsPath);
        document.body.appendChild(markdownLintScript);

        markdownLintScript.addEventListener('load', this.lintMarkdown);
      });
    } else {
      this.lintMarkdown();
    }
  };

  showLoadingPreview = () => {
    this.setState({
      ...this.setCommonProps({
        previewShowing: true,
        previewLoading: true,
      }),
    });
  };

  showPreview = (response) => {
    this.fetchMarkdownLint();
    this.setState({
      ...this.setCommonProps({
        previewShowing: true,
        previewLoading: false,
      }),
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
      ...this.setCommonProps({ previewLoading: false }),
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
    this.setState({ submitting: true });
    const payload = {
      ...this.state,
      published: true,
    };

    submitArticle({
      payload,
      onSuccess: () => {
        this.removeLocalStorage();
        this.setState({ published: true, submitting: false });
      },
      onError: this.handleArticleError,
    });
  };

  onSaveDraft = (e) => {
    e.preventDefault();
    this.setState({ submitting: true });
    const payload = {
      ...this.state,
      published: false,
    };

    submitArticle({
      payload,
      onSuccess: () => {
        this.removeLocalStorage();
        this.setState({ published: false, submitting: false });
      },
      onError: this.handleArticleError,
    });
  };

  onClearChanges = (e) => {
    e.preventDefault();
    // eslint-disable-next-line no-alert
    const revert = window.confirm(
      'Are you sure you want to revert to the previous save?',
    );
    if (!revert && navigator.userAgent !== 'DEV-Native-ios') return;

    this.setState({
      // When the formKey prop changes, it causes the <Form /> component to recreate the DOM nodes that it manages.
      // This permits us to reset the defaultValue for the MentionAutocompleteTextArea component without having to change
      // MentionAutocompleteTextArea component's implementation.
      formKey: new Date().toISOString(),
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '', // eslint-disable-line react/no-unused-state
      canonicalUrl: this.article.canonical_url || '', // eslint-disable-line react/no-unused-state
      publishedAtTime: this.publishedAtTime,
      publishedAtDate: this.publishedAtDate,
      publishedAtWas: this.publishedAtWas,
      series: this.article.series || '', // eslint-disable-line react/no-unused-state
      allSeries: this.article.all_series || [], // eslint-disable-line react/no-unused-state
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      previewLoading: false,
      previewResponse: '',
      submitting: false,
      editing: this.article.id !== null, // eslint-disable-line react/no-unused-state
      mainImage: this.article.main_image || null,
      errors: null,
      edited: false,
      helpFor: null,
      helpPosition: 0,
      isModalOpen: false,
    });
  };

  handleArticleError = (response) => {
    window.scrollTo(0, 0);
    this.setState({
      errors: response,
      submitting: false,
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

  showModal = (isModalOpen) => {
    if (this.state.edited) {
      this.setState({
        isModalOpen,
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
      publishedAtTime,
      publishedAtDate,
      publishedAtWas,
      previewShowing,
      previewLoading,
      previewResponse,
      schedulingEnabled,
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
      markdownLintErrors,
      formKey,
    } = this.state;

    return (
      <form
        ref={(element) => {
          this.formElement = element;
        }}
        id="article-form"
        className="crayons-article-form"
        onSubmit={this.onSubmit}
        onInput={this.toggleEdit}
        aria-label="Edit post"
      >
        <Header
          onPreview={this.fetchPreview}
          previewLoading={previewLoading}
          previewShowing={previewShowing}
          organizations={organizations}
          organizationId={organizationId}
          onToggle={this.handleOrgIdChange}
          siteLogo={siteLogo}
          displayModal={() => this.showModal(true)}
        />

        <span aria-live="polite" className="screen-reader-only">
          {previewLoading ? 'Loading preview' : null}
          {previewShowing && !previewLoading ? 'Preview loaded' : null}
        </span>

        {previewShowing || previewLoading ? (
          <Preview
            previewLoading={previewLoading}
            previewResponse={previewResponse}
            articleState={this.state}
            errors={errors}
            markdownLintErrors={markdownLintErrors}
          />
        ) : (
          <Form
            key={formKey}
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
        {this.state.isModalOpen && (
          <Modal
            size="s"
            title="You have unsaved changes"
            onClose={() => this.showModal(false)}
          >
            <p>
              You've made changes to your post. Do you want to navigate to leave
              this page?
            </p>
            <div className="pt-4">
              <Button className="mr-2" variant="danger" url="/" tagName="a">
                Yes, leave the page
              </Button>
              <Button variant="secondary" onClick={() => this.showModal(false)}>
                No, keep editing
              </Button>
            </div>
          </Modal>
        )}

        <EditorActions
          published={published}
          publishedAtTime={publishedAtTime}
          publishedAtDate={publishedAtDate}
          publishedAtWas={publishedAtWas}
          schedulingEnabled={schedulingEnabled}
          version={version}
          onPublish={this.onPublish}
          onSaveDraft={this.onSaveDraft}
          onClearChanges={this.onClearChanges}
          edited={edited}
          passedData={this.state}
          onConfigChange={this.handleConfigChange}
          submitting={submitting}
          previewLoading={previewLoading}
        />

        <KeyboardShortcuts
          shortcuts={{
            [`${getOSKeyboardModifierKeyString()}+shift+KeyP`]:
              this.fetchPreview,
          }}
        />
      </form>
    );
  }
}
