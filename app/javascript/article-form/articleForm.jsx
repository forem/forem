import 'preact/devtools';
import { h, Component } from 'preact';
import linkState from 'linkstate';
import { submitArticle, previewArticle } from './actions';
import BodyMarkdown from './elements/bodyMarkdown';
import BodyPreview from './elements/bodyPreview';
import Description from './elements/description';
import PublishToggle from './elements/publishToggle';
import Notice from './elements/notice';
import Tags from './elements/tags';
import Title from './elements/title';
import MainImage from './elements/mainImage';
import ImageManagement from './elements/imageManagement';
import OrgSettings from './elements/orgSettings';
import Errors from './elements/errors';
import ImageUploadIcon from 'images/image-upload.svg';
// import CodeMirror from 'codemirror';
// import 'codemirror/mode/markdown/markdown';

export default class ArticleForm extends Component {
  constructor(props) {
    super(props);

    const article = JSON.parse(this.props.article);
    const organization = this.props.organization
      ? JSON.parse(this.props.organization)
      : null;
    console.log(article)
    this.state = {
      id: article.id || null,
      title: article.title || '',
      tagList: article.cached_tag_list || '',
      description: '',
      bodyMarkdown: article.body_markdown || '',
      published: article.published || false,
      previewShowing: false,
      helpShowing: false,
      previewHTML: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: article.id != null,
      imageManagementShowing: false,
      mainImage: article.main_image || null,
      organization,
      postUnderOrg: article.organization_id ? true : false,
      errors: null,
    };
  }

  componentDidMount() {
    initEditorResize();
    console.log('codemirror-ify');
    // const editor = document.getElementById('article_body_markdown');
    // const myCodeMirror = CodeMirror(editor, {
    //   mode: 'markdown',
    //   theme: 'material',
    //   highlightFormatting: true,
    // });
    // myCodeMirror.setSize('100%', '100%');
  }

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

  handleMainImageUrlChange = payload => {
    this.setState({
      mainImage: payload.link,
      imageManagementShowing: false,
    });
  };

  onPublish = e => {
    e.preventDefault();
    this.setState({ submitting: true, published: true });
    const state = this.state;
    state.published = true;
    submitArticle(state, this.handleArticleError);
  };

  onSaveDraft = e => {
    e.preventDefault();
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
      organization,
      postUnderOrg,
      mainImage,
      errors,
    } = this.state;
    // <input type="image" name="cover-image" />

    let bodyArea = '';
    if (previewShowing) {
      bodyArea = <BodyPreview previewHTML={previewHTML} />;
    } else if (helpShowing) {
      bodyArea = <BodyPreview previewHTML={helpHTML} />;
    } else {
      bodyArea = (
        <BodyMarkdown
          defaultValue={bodyMarkdown}
          onChange={linkState(this, 'bodyMarkdown')}
        />
      );
    }

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
    return (
      <form className="articleform__form" onSubmit={this.onSubmit}>
        {errorsArea}
        {orgArea}
        {imageArea}
        <Title defaultValue={title} onChange={linkState(this, 'title')} />
        <div className="articleform__detailfields">
          <Tags defaultValue={tagList} onInput={linkState(this, 'tagList')} />
          <button
            className="articleform__imageButton"
            onClick={this.toggleImageManagement}
          >
            <img src={ImageUploadIcon} /> IMAGES
          </button>
        </div>
        {bodyArea}
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
      </form>
    );
  }
}
