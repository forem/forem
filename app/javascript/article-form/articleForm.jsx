import 'preact/devtools';
import { h, Component } from 'preact';
import linkState from 'linkstate';
import postscribe from 'postscribe';
import ImageUploadIcon from 'images/image-upload.svg';
import ThreeDotsIcon from 'images/three-dots.svg';
import { submitArticle, previewArticle } from './actions';
import BodyMarkdown from './elements/bodyMarkdown';
import BodyPreview from './elements/bodyPreview';
import PublishToggle from './elements/publishToggle';
import Notice from './elements/notice';
import Title from './elements/title';
import MainImage from './elements/mainImage';
import ImageManagement from './elements/imageManagement';
import MoreConfig from './elements/moreConfig';
import OrgSettings from './elements/orgSettings';
import Errors from './elements/errors';
import KeyboardShortcutsHandler from './elements/keyboardShortcutsHandler';
import Tags from '../shared/components/tags';

const setupImageButton = ({ className = '', imgSrc, imgAltText = '', onClickCallback }) => {
  return (
    <button
    type="button"
    className={className}
    onClick={onClickCallback}
    >
      <img src={imgSrc} alt={imgAltText} />
    </button>
  )
}

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

  constructor(props) {
    super(props);
    this.article = JSON.parse(this.props.article);
    const organizations = this.props.organizations
      ? JSON.parse(this.props.organizations)
      : null;

    this.url = window.location.href;

    this.state = {
      id: this.article.id || null,
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '',
      canonicalUrl: this.article.canonical_url || '',
      series: this.article.series || '',
      allSeries: this.article.all_series || [],
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      helpShowing: false,
      previewResponse: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: this.article.id != null,
      imageManagementShowing: false,
      moreConfigShowing: false,
      mainImage: this.article.main_image || null,
      organizations,
      organizationId: this.article.organization_id,
      errors: null,
      edited: false,
      version: this.props.version,
    };
  }

  componentDidMount() {
    const { version } = this.state;
    const previousContent = JSON.parse(
      localStorage.getItem(`editor-${version}-${window.location.href}`),
    );
    if (previousContent && this.checkContentChanges(previousContent)) {
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

  checkContentChanges = previousContent => {
    const { bodyMarkdown, title, mainImage, tagList } = this.state;
    return (
      bodyMarkdown !== previousContent.bodyMarkdown ||
      title !== previousContent.title ||
      mainImage !== previousContent.mainImage ||
      tagList !== previousContent.tagList
    );
  };

  localStoreContent = () => {
    const { version, title, tagList, mainImage, bodyMarkdown } = this.state;
    localStorage.setItem(
      `editor-${version}-${this.url}`,
      JSON.stringify({
        title,
        tagList,
        mainImage,
        bodyMarkdown,
      }),
    );
  };

  toggleHelp = e => {
    const { helpShowing } = this.state;
    e.preventDefault();
    window.scrollTo(0, 0);
    this.setState({
      helpShowing: !helpShowing,
      previewShowing: false,
      imageManagementShowing: false,
      moreConfigShowing: false,
    });
  };

  fetchPreview = e => {
    const { previewShowing, bodyMarkdown } = this.state;
    e.preventDefault();
    if (previewShowing) {
      this.setState({
        previewShowing: false,
        helpShowing: false,
        imageManagementShowing: false,
        moreConfigShowing: false,
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
      imageManagementShowing: !imageManagementShowing,
      previewShowing: false,
      helpShowing: false,
      moreConfigShowing: false,
    });
  };

  toggleMoreConfig = e => {
    const { moreConfigShowing } = this.state;
    e.preventDefault();
    this.setState({
      moreConfigShowing: !moreConfigShowing,
      previewShowing: false,
      helpShowing: false,
      imageManagementShowing: false,
    });
  };

  showPreview = response => {
    if (response.processed_html) {
      this.setState({
        previewShowing: true,
        helpShowing: false,
        imageManagementShowing: false,
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
    // eslint-disable-next-line no-restricted-globals
    const revert = confirm(
      'Are you sure you want to revert to the previous save?',
    );
    if (!revert && navigator.userAgent !== 'DEV-Native-ios') return;
    this.setState({
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '',
      canonicalUrl: this.article.canonical_url || '',
      series: this.article.series || '',
      allSeries: this.article.all_series || [],
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      helpShowing: false,
      previewResponse: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: this.article.id != null,
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
      helpShowing,
      previewResponse,
      helpHTML,
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
    const notice = submitting ? (
      <Notice published={published} version={version} />
    ) : (
      ''
    );
    const imageArea =
      mainImage && !previewShowing && version === 'v2' ? (
        <MainImage mainImage={mainImage} onEdit={this.toggleImageManagement} />
      ) : (
        ''
      );
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
    const moreConfig = moreConfigShowing ? (
      <MoreConfig
        onExit={this.toggleMoreConfig}
        passedData={this.state}
        onSaveDraft={this.onSaveDraft}
        onConfigChange={this.handleConfigChange}
      />
    ) : (
      ''
    );
    const orgArea =
      organizations && organizations.length > 0 ? (
        <OrgSettings
          organizations={organizations}
          organizationId={organizationId}
          onToggle={this.handleOrgIdChange}
        />
      ) : (
        ''
      );
    const errorsArea = errors ? <Errors errorsList={errors} /> : '';
    let editorView = '';
    if (previewShowing) {
      editorView = (
        <div>
          {errorsArea}
          {orgArea}
          {imageArea}
          <BodyPreview
            previewResponse={previewResponse}
            articleState={this.state}
            version="article-preview"
          />
        </div>
      );
    } else if (helpShowing) {
      editorView = (
        <BodyPreview
          previewResponse={{ processed_html: helpHTML }}
          version="help"
        />
      );
    } else {
      let controls = '';
      let moreConfigBottomButton = '';
      if (version === 'v2') {
        moreConfigBottomButton = (
          setupImageButton({
            className: 'articleform__detailsButton articleform__detailsButton--moreconfig articleform__detailsButton--bottom',
            imgSrc: ThreeDotsIcon,
            imgAltText: 'menu dots',
            onClickCallback: this.toggleMoreConfig
          })
        );
        controls = (
          <div
            className={title.length > 128 ? 'articleform__titleTooLong' : ''}
          >
            <Title
              defaultValue={title}
              onKeyDown={this.handleTitleKeyDown}
              onChange={linkState(this, 'title')}
            />
            <div className="articleform__detailfields">
              <Tags
                defaultValue={tagList}
                onInput={linkState(this, 'tagList')}
                maxTags={4}
                autoComplete='off'
                classPrefix='articleform'
              />
              {
                setupImageButton({
                  className: 'articleform__detailsButton articleform__detailsButton--image',
                  imgSrc: ImageUploadIcon,
                  imgAltText: 'Upload images',
                  onClickCallback: this.toggleImageManagement
                })
              }
              {
                setupImageButton({
                  className: 'articleform__detailsButton articleform__detailsButton--moreconfig',
                  imgSrc: ThreeDotsIcon,
                  imgAltText: 'Menu',
                  onClickCallback: this.toggleMoreConfig
                })
              }
            </div>
          </div>
        );
      }
      editorView = (
        <div>
          {errorsArea}
          {orgArea}
          {imageArea}
          {controls}
          <BodyMarkdown
            defaultValue={bodyMarkdown}
            onKeyDown={this.handleBodyKeyDown}
            onChange={linkState(this, 'bodyMarkdown')}
          />
          <button
            className="articleform__detailsButton articleform__detailsButton--image articleform__detailsButton--bottom"
            onClick={this.toggleImageManagement}
            type="button"
          >
            <img src={ImageUploadIcon} alt="upload images" />
            IMAGES
          </button>
          {moreConfigBottomButton}
        </div>
      );
    }
    return (
      <form
        className={`articleform__form articleform__form--${version}`}
        onSubmit={this.onSubmit}
        onInput={this.toggleEdit}
      >
        {editorView}
        <PublishToggle
          published={published}
          version={version}
          previewShowing={previewShowing}
          helpShowing={helpShowing}
          onPreview={this.fetchPreview}
          onPublish={this.onPublish}
          onHelp={this.toggleHelp}
          onSaveDraft={this.onSaveDraft}
          onClearChanges={this.onClearChanges}
          edited={edited}
          onChange={linkState(this, 'published')}
        />
        <KeyboardShortcutsHandler togglePreview={this.fetchPreview} />
        {notice}
        {imageManagement}
        {moreConfig}
      </form>
    );
  }
}
