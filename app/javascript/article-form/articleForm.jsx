import 'preact/devtools';
import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkState from 'linkstate';
import postscribe from 'postscribe';
// eslint-disable-next-line import/no-unresolved
import ImageUploadIcon from 'images/image-upload.svg';
// eslint-disable-next-line import/no-unresolved
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
import Errors from './elements/errors';
import KeyboardShortcutsHandler from './elements/keyboardShortcutsHandler';
import Tags from '../shared/components/tags';
import { OrganizationPicker } from '../organization/OrganizationPicker';

const SetupImageButton = ({
  className,
  imgSrc,
  imgAltText,
  onClickCallback,
}) => (
  <button type="button" className={className} onClick={onClickCallback}>
    <img src={imgSrc} alt={imgAltText} />
  </button>
);

SetupImageButton.propTypes = {
  className: PropTypes.string.isRequired,
  imgSrc: PropTypes.string.isRequired,
  imgAltText: PropTypes.string.isRequired,
  onClickCallback: PropTypes.func.isRequired,
};

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
      helpShowing: false,
      previewResponse: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
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
    helpShowing = false,
    previewShowing = false,
    imageManagementShowing = false,
    moreConfigShowing = false,
  }) => {
    return {
      helpShowing,
      previewShowing,
      imageManagementShowing,
      moreConfigShowing,
    };
  };

  toggleHelp = e => {
    const { helpShowing } = this.state;
    e.preventDefault();
    window.scrollTo(0, 0);
    this.setState({
      ...this.setCommonProps({ helpShowing: !helpShowing }),
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
      helpShowing: false,
      previewResponse: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
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
        <div className="articleform__orgsettings">
          Publish under an organization:
          <OrganizationPicker
            name="article[organization_id]"
            id="article_publish_under_org"
            organizations={organizations}
            organizationId={organizationId}
            onToggle={this.handleOrgIdChange}
          />
        </div>
      ) : null;
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
          <SetupImageButton
            className="articleform__detailsButton articleform__detailsButton--moreconfig articleform__detailsButton--bottom"
            imgSrc={ThreeDotsIcon}
            imgAltText="menu dots"
            onClickCallback={this.toggleMoreConfig}
          />
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
                autoComplete="off"
                classPrefix="articleform"
              />
              <SetupImageButton
                className="articleform__detailsButton articleform__detailsButton--image"
                imgSrc={ImageUploadIcon}
                imgAltText="Upload images"
                onClickCallback={this.toggleImageManagement}
              />
              <SetupImageButton
                className="articleform__detailsButton articleform__detailsButton--moreconfig"
                imgSrc={ThreeDotsIcon}
                imgAltText="Menu"
                onClickCallback={this.toggleMoreConfig}
              />
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
