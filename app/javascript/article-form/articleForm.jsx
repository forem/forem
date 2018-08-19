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
import CodeMirror from 'codemirror';
import 'codemirror/mode/markdown/markdown';

export default class ArticleForm extends Component {
  constructor(props) {
    super(props);

    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
      .content;
    const algoliaKey = document.querySelector("meta[name='algolia-public-key']")
      .content;
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey);
    this.index = client.initIndex(`Tag_${  env}`);

    const article = JSON.parse(this.props.article);
    const organization = this.props.organization
      ? JSON.parse(this.props.organization)
      : null;
    this.state = {
      id: article.id || null,
      title: article.title || '',
      tagList: article.cached_tag_list || '',
      description: '',
      bodyMarkdown: article.body_markdown || '',
      published: article.published || false,
      tagOptions: [],
      selectedTags: [],
      tagInputListIndex: -1,
      previewShowing: false,
      helpShowing: false,
      previewHTML: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: article.id != null,
      imageManagementShowing: false,
      mainImageUrl: article.main_image || null,
      organization,
      postUnderOrg: false,
      errors: null,
    };
  }

  componentDidMount() {
    initEditorResize();
    console.log('codemirror-ify');
    const editor = document.getElementById('article_body_markdown');
    const myCodeMirror = CodeMirror(editor, {
      mode: 'markdown',
      theme: 'material',
      highlightFormatting: true,
    });
    myCodeMirror.setSize('100%', '100%');
  }

  handleTagKeyUp = e => {
    const component = this;
    const inputArray = e.target.value.split(',');
    component.setState({
      tagList: e.target.value,
    });
    const query = inputArray[inputArray.length - 1].replace(/ /g, '');
    if (query === '' && e.target.value != '') {
      component.setState({
        tagOptions: [],
      });
      return;
    } else if (e.target.value === '') {
      component.setState({
        tagOptions: [],
        tagList: '',
        selectedTags: [],
      });
      return;
    }
    return this.index.search(query, {
      hitsPerPage: 10,
      filters: 'supported:true',
    })
      .then((content) => {
        component.setState({
          tagOptions: content.hits.filter(
            hit => !component.state.selectedTags.includes(hit.name),
          ),
        });
      });
  };

  handleTagKeyDown = e => {
    const component = this;
    const keyCode = e.keyCode;
    if (component.state.selectedTags.length === 4 && e.keyCode === KEYS.COMMA) {
      e.preventDefault();
      return;
    }
    if (
      (e.keyCode === KEYS.DOWN || e.keyCode === KEYS.TAB) &&
      component.state.tagInputListIndex <
        component.state.tagOptions.length - 1 &&
      component.state.tagList != ''
    ) {
      // down key or tab key
      e.preventDefault();
      this.setState({
        tagInputListIndex: component.state.tagInputListIndex + 1,
      });
    } else if (
      e.keyCode === KEYS.UP &&
      component.state.tagInputListIndex > -1
    ) {
      // up key
      e.preventDefault();
      this.setState({
        tagInputListIndex: component.state.tagInputListIndex - 1,
      });
    } else if (
      e.keyCode === KEYS.RETURN &&
      component.state.tagInputListIndex > -1
    ) {
      // return key
      e.preventDefault();
      const newInput =
        `${component.state.selectedTags +
        component.state.tagOptions[component.state.tagInputListIndex].name
        },`;
      document.getElementById('tag-input').value = newInput;
      component.setState({
        tagOptions: [],
        tagList: newInput,
        tagInputListIndex: -1,
        selectedTags: newInput.split(','),
      });
      setTimeout(() => {
        document.getElementById('tag-input').focus();
      }, 10);
    } else if (
      e.keyCode === KEYS.COMMA &&
      component.state.tagInputListIndex === -1
    ) {
      // comma key
      e.preventDefault();
      const newInput = `${component.state.tagList  },`;
      document.getElementById('tag-input').value = newInput;
      component.setState({
        tagOptions: [],
        tagList: newInput,
        tagInputListIndex: -1,
        selectedTags: newInput.split(','),
      });
    } else if (e.keyCode === KEYS.DELETE) {
      // Delete key
      if (component.state.tagList[component.state.tagList.length - 1] === ',') {
        const selectedTags = component.state.selectedTags;
        component.setState({
          tagInputListIndex: -1,
          selectedTags: selectedTags.slice(0, selectedTags.length - 2),
        });
      }
    } else if (
      (e.keyCode < 65 || e.keyCode > 90) &&
      e.keyCode != KEYS.COMMA &&
      e.keyCode != KEYS.DELETE &&
      e.keyCode != KEYS.LEFT &&
      e.keyCode != KEYS.RIGHT &&
      e.keyCode != KEYS.TAB
    ) {
      // not letter or comma or delete
      e.preventDefault();
    }
  };

  handleTagClick = e => {
    document.getElementById('tag-input').focus();
    const newInput = `${this.state.selectedTags + e.target.dataset.content  },`;
    document.getElementById('tag-input').value = newInput;
    console.log('CLICK');
    this.setState({
      tagOptions: [],
      tagList: newInput,
      tagInputListIndex: -1,
      selectedTags: newInput.split(','),
    });
  };

  handleFocusChange = e => {
    const component = this;
    setTimeout(() => {
      if (document.activeElement.id === 'tag-input') {
        return;
      }
      component.forceUpdate();
    }, 100);
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
      mainImageUrl: payload.link,
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
      tagOptions,
      tagInputListIndex,
      previewShowing,
      helpShowing,
      previewHTML,
      helpHTML,
      submitting,
      imageManagementShowing,
      organization,
      postUnderOrg,
      mainImageUrl,
      errors,
    } = this.state;
    // <input type="image" name="cover-image" />
    let tagOptionsHTML = '';
    const component = this;
    const tagOptionRows = tagOptions.map((tag, index) => (
      <div
        tabIndex="-1"
        className={
            `articleform__tagoptionrow articleform__tagoptionrow--${
            tagInputListIndex === index ? 'active' : 'inactive'}`
          }
        onClick={component.handleTagClick}
        data-content={tag.name}
      >
        {tag.name}
      </div>
      ));
    if (tagOptions.length > 0 && document.activeElement.id === 'tag-input') {
      tagOptionsHTML = (
        <div className="articleform__tagsoptions">{tagOptionRows}</div>
      );
    }

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
    const imageArea = mainImageUrl ? (
      <MainImage mainImage={mainImageUrl} onEdit={this.toggleImageManagement} />
    ) : (
      ''
    );
    const imageManagement = imageManagementShowing ? (
      <ImageManagement
        onExit={this.toggleImageManagement}
        mainImageUrl={mainImageUrl}
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
          <Tags
            defaultValue={tagList}
            onKeyDown={this.handleTagKeyDown}
            onKeyUp={this.handleTagKeyUp}
            options={tagOptionsHTML}
            onFocusChange={this.handleFocusChange}
          />
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

const KEYS = {
  UP: 38,
  DOWN: 40,
  LEFT: 37,
  RIGHT: 39,
  TAB: 9,
  RETURN: 13,
  COMMA: 188,
  DELETE: 8,
};
