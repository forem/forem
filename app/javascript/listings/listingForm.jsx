import { h, Component } from 'preact';
import linkState from 'linkstate';
import Title from './elements/title';
import BodyMarkdown from './elements/bodyMarkdown';
import Categories from './elements/categories';
import Tags from './elements/tags';


export default class ListingForm extends Component {
  constructor(props) {
    super(props);

    this.listing = JSON.parse(this.props.listing);
    this.categoriesForDetails = JSON.parse(this.props.categoriesForDetails);
    this.categoriesForSelect = JSON.parse(this.props.categoriesForSelect);

    const organizations = this.props.organizations
      ? JSON.parse(this.props.organizations) : null;

    this.url = window.location.href;

    this.state = {
      id: this.listing.id || null,
      title: this.listing.title || '',
      category: this.listing.category || '',
      tagList: this.listing.cached_tag_list || '',
      bodyMarkdown: this.listing.body_markdown || '',
      organizations: organizations || null,
      categoriesForSelect: this.categoriesForSelect,
      categoriesForDetails: this.categoriesForDetails,
    }
  }

  render() {
    const {
      id,
      title,
      bodyMarkdown,
      tagList,
      category,
      organizations,
      categoriesForDetails,
      categoriesForSelect,
    } = this.state;
    if (id === null) {
      return(
        <div>
          <Title defaultValue={title} onChange={linkState(this, 'title')} />
          <BodyMarkdown defaultValue={bodyMarkdown} onChange={linkState(this, 'bodyMarkdown')} />
          <Categories categoriesForSelect={categoriesForSelect} categoriesForDetails={categoriesForDetails} onChange={linkState(this, 'category')} />
          <Tags defaultValue={tagList} category={category} onInput={linkState(this, 'tagList')} />
          {/* add contact via connect checkbox later */}
        </div>
      )
    }
    return(
      <div>
        <Title defaultValue={title} onChange={linkState(this, 'title')} />
        <BodyMarkdown defaultValue={bodyMarkdown} onChange={linkState(this, 'bodyMarkdown')} />
        <Tags defaultValue={tagList} onInput={linkState(this, 'tagList')} />
        {/* add contact via connect checkbox later */}
      </div>
      )
  }
}
