import { h, Component } from 'preact';
import linkState from 'linkstate';
import Title from './elements/title';
import BodyMarkdown from './elements/bodyMarkdown';
import Categories from './elements/categories';
import Tags from './elements/tags';
import OrgSettings from './elements/orgSettings';

export default class ListingForm extends Component {
  constructor(props) {
    super(props);

    this.listing = JSON.parse(this.props.listing);
    this.categoriesForDetails = JSON.parse(this.props.categoriesForDetails);
    this.categoriesForSelect = JSON.parse(this.props.categoriesForSelect);

    const organizations = JSON.parse(this.props.organizations);

    this.url = window.location.href;

    this.state = {
      id: this.listing.id || null,
      title: this.listing.title || '',
      category: this.listing.category || '',
      tagList: this.listing.cached_tag_list || '',
      bodyMarkdown: this.listing.body_markdown || '',
      categoriesForSelect: this.categoriesForSelect,
      categoriesForDetails: this.categoriesForDetails,
      organizations,
      organizationId: null, // change this for /edit later
    };
  }

  handleOrgIdChange = e => {
    const organizationId = e.target.selectedOptions[0].value;
    this.setState({ organizationId });
  };

  render() {
    const {
      id,
      title,
      bodyMarkdown,
      tagList,
      category,
      categoriesForDetails,
      categoriesForSelect,
      organizations,
      organizationId,
    } = this.state;
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
    if (id === null) {
      return (
        <div>
          <Title defaultValue={title} onChange={linkState(this, 'title')} />
          <BodyMarkdown
            defaultValue={bodyMarkdown}
            onChange={linkState(this, 'bodyMarkdown')}
          />
          <Categories
            categoriesForSelect={categoriesForSelect}
            categoriesForDetails={categoriesForDetails}
            onChange={linkState(this, 'category')}
            category={category}
          />
          <Tags
            defaultValue={tagList}
            category={category}
            onInput={linkState(this, 'tagList')}
          />
          {orgArea}
          {/* add contact via connect checkbox later */}
        </div>
      );
    }
    // WIP code for edit
    return (
      <div>
        <Title defaultValue={title} onChange={linkState(this, 'title')} />
        <BodyMarkdown
          defaultValue={bodyMarkdown}
          onChange={linkState(this, 'bodyMarkdown')}
        />
        <Tags defaultValue={tagList} onInput={linkState(this, 'tagList')} />
        {orgArea}
        {/* add contact via connect checkbox later */}
      </div>
    );
  }
}
