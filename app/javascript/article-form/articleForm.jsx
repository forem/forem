import 'preact/devtools';
import { h, Component } from 'preact';
import linkState from 'linkstate';
import ImageUploadIcon from 'images/image-upload.svg';
import ThreeDotsIcon from 'images/three-dots.svg';
import { submitArticle, previewArticle } from './actions';
import BodyMarkdown from './elements/bodyMarkdown';
import BodyPreview from './elements/bodyPreview';
// import Description from './elements/description';
import PublishToggle from './elements/publishToggle';
import Notice from './elements/notice';
import Tags from './elements/tags';
import Title from './elements/title';
import MainImage from './elements/mainImage';
import ImageManagement from './elements/imageManagement';
import MoreConfig from './elements/moreConfig';
import OrgSettings from './elements/orgSettings';
import Errors from './elements/errors';
// import CodeMirror from 'codemirror';
// import 'codemirror/mode/markdown/markdown';

export default class ArticleForm extends Component {
  constructor(props) {
    super(props);

    const article = JSON.parse(this.props.article);
    const organization = this.props.organization
      ? JSON.parse(this.props.organization)
      : null;

    this.url = window.location.href;

    this.state = {
      id: article.id || null,
      title: article.title || '',
      tagList: article.cached_tag_list || '',
      description: '',
      canonicalUrl: article.canonical_url || '',
      series: article.series || '',
      allSeries: article.all_series || [],
      bodyMarkdown: article.body_markdown || '',
      published: article.published || false,
      previewShowing: false,
      helpShowing: false,
      previewHTML: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: article.id != null,
      imageManagementShowing: false,
      moreConfigShowing: false,
      mainImage: article.main_image || null,
      organization,
      postUnderOrg: !!article.organization_id,
      errors: null,
    };
  }

  componentDidMount() {
    initEditorResize();

    window.addEventListener('beforeunload', this.sessionStoreContent);

    const previousContent = JSON.parse(
      sessionStorage.getItem(window.location.href),
    );

    if (previousContent) {
      this.setState({
        title: previousContent.title || '',
        tagList: previousContent.tagList || '',
        mainImage: previousContent.mainImage || null,
        bodyMarkdown: previousContent.bodyMarkdown || '',
      });
    }
    // const editor = document.getElementById('article_body_markdown');
    // const myCodeMirror = CodeMirror(editor, {
    //   mode: 'markdown',
    //   theme: 'material',
    //   highlightFormatting: true,
    // });
    // myCodeMirror.setSize('100%', '100%');
  }

  sessionStoreContent = e => {
    sessionStorage.setItem(
      this.url,
      JSON.stringify({
        title: this.state.title,
        tagList: this.state.tagList,
        mainImage: this.state.mainImage,
        bodyMarkdown: this.state.bodyMarkdown,
      }),
    );
    e.returnValue = '';
  };

  toggleHelp = e => {
    e.preventDefault();
    window.scrollTo(0, 0);
    this.setState({
      helpShowing: !this.state.helpShowing,
      previewShowing: false,
    });
  };

  fetchPreview = e => {
    e.preventDefault();
    if (this.state.previewShowing) {
      this.setState({
        previewShowing: false,
        helpShowing: false,
      });
    } else {
      previewArticle(
        this.state.bodyMarkdown,
        this.showPreview,
        this.failedPreview,
      );
    }
  };

  toggleImageManagement = e => {
    e.preventDefault();
    this.setState({
      imageManagementShowing: !this.state.imageManagementShowing,
    });
  };

  toggleMoreConfig = e => {
    e.preventDefault();
    this.setState({
      moreConfigShowing: !this.state.moreConfigShowing,
    });
  };

  showPreview = response => {
    this.setState({
      previewShowing: true,
      helpShowing: false,
      previewHTML: response.processed_html,
    });
  };

  toggleOrgPosting = e => {
    e.preventDefault();
    this.setState({ postUnderOrg: !this.state.postUnderOrg });
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
      mainImage: payload.link,
      imageManagementShowing: false,
    });
  };

  removeSessionStorage = () => {
    sessionStorage.removeItem(this.url);
    window.removeEventListener('beforeunload', this.sessionStoreContent);
  };

  onPublish = e => {
    e.preventDefault();
    this.removeSessionStorage();
    this.setState({ submitting: true, published: true });
    const state = this.state;
    state.published = true;
    submitArticle(state, this.handleArticleError);
  };

  onSaveDraft = e => {
    e.preventDefault();
    this.removeSessionStorage();
    this.setState({ submitting: true, published: false });
    const state = this.state;
    state.published = false;
    submitArticle(state, this.handleArticleError);
  };

  handleArticleError = response => {
    window.scrollTo(0, 0);
    this.setState({
      errors: response,
      submitting: false,
    });
  };

  render() {
    // cover image url should asking for url OR providing option to upload an image
    const {
      title,
      tagList,
      description,
      bodyMarkdown,
      published,
      previewShowing,
      helpShowing,
      previewHTML,
      helpHTML,
      submitting,
      imageManagementShowing,
      moreConfigShowing,
      organization,
      postUnderOrg,
      mainImage,
      errors,
    } = this.state;
    const notice = submitting ? <Notice published={published} /> : '';
    const imageArea = mainImage ? (
      <MainImage mainImage={mainImage} onEdit={this.toggleImageManagement} />
    ) : (
        ''
      );
    const imageManagement = imageManagementShowing ? (
      <ImageManagement
        onExit={this.toggleImageManagement}
        mainImage={mainImage}
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
    const orgArea = organization ? (
      <OrgSettings
        organization={organization}
        postUnderOrg={postUnderOrg}
        onToggle={this.toggleOrgPosting}
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
            previewHTML={previewHTML}
            articleState={this.state}
            version="article-preview"
          />
        </div>
      );
    } else if (helpShowing) {
      editorView = <BodyPreview previewHTML={helpHTML} version="help" />;
    } else {
      editorView = (
        <div>
          {errorsArea}
          {orgArea}
          {imageArea}
          <Title defaultValue={title} onChange={linkState(this, 'title')} />
          <div className="articleform__detailfields">
            <Tags defaultValue={tagList} onInput={linkState(this, 'tagList')} />
            <button
              className="articleform__detailsButton articleform__detailsButton--image"
              onClick={this.toggleImageManagement}
            >
              <img src={ImageUploadIcon} />
              {' '}
              IMAGES
            </button>
            <button
              className="articleform__detailsButton articleform__detailsButton--moreconfig"
              onClick={this.toggleMoreConfig}
            >
              <img src={ThreeDotsIcon} />
            </button>
          </div>
          <BodyMarkdown
            defaultValue={bodyMarkdown}
            onChange={linkState(this, 'bodyMarkdown')}
          />
          <button
            className="articleform__detailsButton articleform__detailsButton--image articleform__detailsButton--bottom"
            onClick={this.toggleImageManagement}
          >
            <img src={ImageUploadIcon} />
            {' '}
            IMAGES
          </button>
          <button
            className="articleform__detailsButton articleform__detailsButton--moreconfig articleform__detailsButton--bottom"
            onClick={this.toggleMoreConfig}
          >
            <img src={ThreeDotsIcon} />
          </button>
        </div>
      );
    }
    return (
      <form className="articleform__form" onSubmit={this.onSubmit}>
        {editorView}
        <PublishToggle
          published={published}
          previewShowing={previewShowing}
          helpShowing={helpShowing}
          onPreview={this.fetchPreview}
          onPublish={this.onPublish}
          onHelp={this.toggleHelp}
          onSaveDraft={this.onSaveDraft}
          onChange={linkState(this, 'published')}
        />
        {notice}
        {imageManagement}
        {moreConfig}
      </form>
    );
  }
}
