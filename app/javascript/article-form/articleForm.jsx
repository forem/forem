import 'preact/devtools';
import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkState from 'linkstate';
import postscribe from 'postscribe';
import { submitArticle, previewArticle } from './actions';
import ImageManagement from './elements/imageManagement';
import Errors from './elements/errors';
import KeyboardShortcutsHandler from './elements/keyboardShortcutsHandler';

import {
  Actions,
  Form,
  Header,
  Help,
  Preview,
} from './components';

/*
  Although the state fields: id, description, canonicalUrl, series, allSeries and
  editing are not used in this file, they are important to the
  editor.
*/
export default class ArticleForm extends Component {
  static handleGistPreview() {
    const els = document.getElementsByClassName('ltag_gist-liquid-tag');
    for (let i = 0; i < els.length; i += 1) {
      postscribe(els[i], els[i].firstElementChild.outerHTML);
    }
  }

  static handleRunkitPreview() {
    const targets = document.getElementsByClassName('runkit-element');
    for (let i = 0; i < targets.length; i += 1) {
      if (targets[i].children.length > 0) {
        const preamble = targets[i].children[0].textContent;
        const content = targets[i].children[1].textContent;
        targets[i].innerHTML = '';
        window.RunKit.createNotebook({
          element: targets[i],
          source: content,
          preamble,
        });
      }
    }
  }

  static propTypes = {
    version: PropTypes.string.isRequired,
    article: PropTypes.string.isRequired,
    organizations: PropTypes.string,
  };

  static defaultProps = {
    organizations: '',
  };

  constructor(props) {
    super(props);
    const { article, version } = this.props;
    let { organizations } = this.props;
    this.article = JSON.parse(article);
    organizations = organizations ? JSON.parse(organizations) : null;

    this.url = window.location.href;
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
      modalShowing: false,
      previewResponse: '',
      // helpHTML: document.getElementById('editor-help-guide').innerHTML,
      liquidHelpHTML: document.getElementById('editor-liquid-help').innerHTML,
      markdownHelpHTML: document.getElementById('editor-markdown-help').innerHTML,
      submitting: false,
      editing: this.article.id !== null, // eslint-disable-line react/no-unused-state
      imageManagementShowing: false,
      moreConfigShowing: false,
      mainImage: this.article.main_image || null,
      organizations,
      organizationId: this.article.organization_id,
      errors: null,
      edited: false,
      updatedAt: this.article.updated_at,
      version,
    };
  }

  componentDidMount() {
    const { version, updatedAt } = this.state;
    const previousContent =
      JSON.parse(
        localStorage.getItem(`editor-${version}-${window.location.href}`),
      ) || {};
    const isLocalstorageNewer =
      new Date(previousContent.updatedAt) > new Date(updatedAt);

    if (previousContent && isLocalstorageNewer) {
      this.setState({
        title: previousContent.title || '',
        tagList: previousContent.tagList || '',
        mainImage: previousContent.mainImage || null,
        bodyMarkdown: previousContent.bodyMarkdown || '',
        edited: true,
      });
    }

    window.addEventListener('beforeunload', this.localStoreContent);
  }

  componentDidUpdate() {
    const { previewResponse } = this.state;
    if (previewResponse) {
      this.constructor.handleGistPreview();
      this.constructor.handleRunkitPreview();
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
    modalShowing = false,
    previewShowing = false,
    imageManagementShowing = false,
    moreConfigShowing = false,
  }) => {
    return {
      modalShowing,
      previewShowing,
      imageManagementShowing,
      moreConfigShowing,
    };
  };

  toggleHelp = e => {
    const { modalShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({ modalShowing: !modalShowing }),
    });
  };

  fetchPreview = e => {
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

  toggleImageManagement = e => {
    const { imageManagementShowing } = this.state;
    e.preventDefault();
    window.scrollTo(0, 0);
    this.setState({
      ...this.setCommonProps({
        imageManagementShowing: !imageManagementShowing,
      }),
    });
  };

  toggleMoreConfig = e => {
    const { moreConfigShowing } = this.state;
    e.preventDefault();
    this.setState({
      ...this.setCommonProps({ moreConfigShowing: !moreConfigShowing }),
    });
  };

  showPreview = response => {
    if (response.processed_html) {
      this.setState({
        ...this.setCommonProps({ previewShowing: true }),
        previewResponse: response,
        errors: null,
      });
    } else {
      this.setState({
        errors: response,
        submitting: false,
      });
    }
  };

  handleOrgIdChange = e => {
    const organizationId = e.target.selectedOptions[0].value;
    this.setState({ organizationId });
  };

  failedPreview = response => {
    // TODO: console.log should not be part of production code. Remove it!
    // eslint-disable-next-line no-console
    console.log(response);
  };

  handleConfigChange = e => {
    e.preventDefault();
    const newState = {};
    newState[e.target.name] = e.target.value;
    this.setState(newState);
  };

  handleMainImageUrlChange = payload => {
    this.setState({
      mainImage: payload.links[0],
      imageManagementShowing: false,
    });
  };

  removeLocalStorage = () => {
    const { version } = this.state;
    localStorage.removeItem(`editor-${version}-${this.url}`);
    window.removeEventListener('beforeunload', this.localStoreContent);
  };

  onPublish = e => {
    e.preventDefault();
    this.setState({ submitting: true, published: true });
    const { state } = this;
    state.published = true;
    submitArticle(state, this.removeLocalStorage, this.handleArticleError);
  };

  onSaveDraft = e => {
    e.preventDefault();
    this.setState({ submitting: true, published: false });
    const { state } = this;
    state.published = false;
    submitArticle(state, this.removeLocalStorage, this.handleArticleError);
  };

  handleTitleKeyDown = e => {
    if (e.keyCode === 13) {
      e.preventDefault();
    }
  };

  handleBodyKeyDown = _e => {};

  onClearChanges = e => {
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
      modalShowing: false,
      previewResponse: '',
      // helpHTML: document.getElementById('editor-help-guide').innerHTML,
      liquidHelpHTML: document.getElementById('editor-liquid-help').innerHTML,
      markdownHelpHTML: document.getElementById('editor-markdown-help').innerHTML,
      submitting: false,
      editing: this.article.id !== null, // eslint-disable-line react/no-unused-state
      imageManagementShowing: false,
      moreConfigShowing: false,
      mainImage: this.article.main_image || null,
      errors: null,
      edited: false,
    });
  };

  handleArticleError = response => {
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

  render() {
    // cover image url should asking for url OR providing option to upload an image
    const {
      title,
      tagList,
      bodyMarkdown,
      published,
      previewShowing,
      modalShowing,
      previewResponse,
      // helpHTML,
      liquidHelpHTML,
      markdownHelpHTML,
      submitting,
      imageManagementShowing,
      moreConfigShowing,
      organizations,
      organizationId,
      mainImage,
      errors,
      edited,
      version,
    } = this.state;

    const imageManagement = imageManagementShowing ? (
      <ImageManagement
        onExit={this.toggleImageManagement}
        mainImage={mainImage}
        version={version}
        onMainImageUrlChange={this.handleMainImageUrlChange}
      />
    ) : (
      ''
    );

    const errorsArea = errors ? <Errors errorsList={errors} /> : '';
    // let editorView = '';
    if (previewShowing) {
      //
    } else if (modalShowing) {
      // editorView = (
      //   <BodyPreview
      //     previewResponse={{ processed_html: helpHTML }}
      //     version="help"
      //   />
      // );
    } else {
      let controls = '';
      if (version === 'v2') {
        controls = (
          <button type="button" onClick={this.toggleImageManagement}>
            Upload images
          </button>
        );
      }
    }
    return (
      <form
        id="article-form"
        className={`crayons-article-form articleform__form articleform__form--${version}`}
        onSubmit={this.onSubmit}
        onInput={this.toggleEdit}
      >
        <Header
          onPreview={this.fetchPreview}
          previewShowing={previewShowing}
          organizations={organizations}
          organizationId={organizationId}
          onToggle={this.handleOrgIdChange}
        />

        <div className="crayons-layout crayons-layout--article-form">
          {!previewShowing && (
            <Form
              titleDefaultValue={title}
              titleOnKeyDown={this.handleTitleKeyDown}
              titleOnChange={linkState(this, 'title')}
              tagsDefaultValue={tagList}
              tagsOnInput={linkState(this, 'tagList')}
              bodyDefaultValue={bodyMarkdown}
              bodyOnKeyDown={this.handleBodyKeyDown}
              bodyOnChange={linkState(this, 'bodyMarkdown')}
              bodyHasFocus={false}
              version={version}
              mainImage={mainImage}
              onMainImageUrlChange={this.handleMainImageUrlChange}
            />
          )}
          {previewShowing && (
            <Preview
              previewResponse={previewResponse}
              articleState={this.state}
              version="article-preview"
            />
          )}
          <Help
            previewShowing={previewShowing}
            toggleHelp={this.toggleHelp}
            modalShowing={modalShowing}
          />
        </div>

        <Actions
          published={published}
          version={version}
          onPublish={this.onPublish}
          onSaveDraft={this.onSaveDraft}
          onClearChanges={this.onClearChanges}
          edited={edited}
          passedData={this.state}
          onConfigChange={this.handleConfigChange}
          toggleMoreConfig={this.toggleMoreConfig}
          moreConfigShowing={moreConfigShowing}
          submitting={submitting}
        />

        <KeyboardShortcutsHandler togglePreview={this.fetchPreview} />
        {/* {imageManagement} */}
      </form>
    );
  }
}
