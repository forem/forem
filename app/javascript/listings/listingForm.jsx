import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkState from 'linkstate';
import { ListingTagsField } from '../listings/components/ListingTagsField';
import { OrganizationPicker } from '../organization/OrganizationPicker';
import { Title } from './components/Title';
import { BodyMarkdown } from './components/BodyMarkdown';
import { Categories } from './components/Categories';
import { ExpireDate } from './components/ExpireDate';

export class ListingForm extends Component {
  constructor(props) {
    super(props);
    const {
      listing,
      categoriesForDetails,
      categoriesForSelect,
      organizations: unparsedOrganizations,
    } = this.props;
    this.listing = JSON.parse(listing);
    this.categoriesForDetails = JSON.parse(categoriesForDetails);
    this.categoriesForSelect = JSON.parse(categoriesForSelect);

    const organizations = JSON.parse(unparsedOrganizations);

    this.url = window.location.href;

    this.state = {
      id: this.listing.id || null,
      title: this.listing.title || '',
      categoryId: this.listing.listing_category_id || '',
      categorySlug:
        this.listing.category || this.categoriesForSelect[0][1] || '',
      tagList: this.listing.cached_tag_list || '',
      bodyMarkdown: this.listing.body_markdown || '',
      categoriesForSelect: this.categoriesForSelect,
      categoriesForDetails: this.categoriesForDetails,
      organizations,
      organizationId: null, // change this for /edit later
      expireDate: this.listing.expires_at || '',
    };
  }

  handleOrgIdChange = (e) => {
    const organizationId = e.target.selectedOptions[0].value;
    this.setState({ organizationId });
  };

  render() {
    const {
      id,
      title,
      bodyMarkdown,
      tagList,
      categoryId,
      categorySlug,
      categoriesForDetails,
      categoriesForSelect,
      organizations,
      organizationId,
      expireDate,
    } = this.state;

    const selectOrg =
      organizations && organizations.length > 0 ? (
        <div className="crayons-field">
          <label htmlFor="organizationId" className="crayons-field__label">
            Post under an organization
          </label>
          <OrganizationPicker
            name="listing[organization_id]"
            id="listing_organization_id"
            className="crayons-select m:max-w-50"
            organizations={organizations}
            organizationId={organizationId}
            onToggle={this.handleOrgIdChange}
          />
          <p className="crayons-field__description">
            Posting on behalf of an organization spends the organization's
            credits.
          </p>
        </div>
      ) : null;

    if (id === null) {
      return (
        <div className="grid gap-6">
          <Title defaultValue={title} onChange={linkState(this, 'title')} />
          <BodyMarkdown
            defaultValue={bodyMarkdown}
            onChange={linkState(this, 'bodyMarkdown')}
          />
          <Categories
            categoriesForSelect={categoriesForSelect}
            categoriesForDetails={categoriesForDetails}
            onChange={(e) => {
              const categoryId = e.target.value;
              const categorySlug = e.target.selectedOptions[0].dataset.slug;
              this.setState({ categoryId, categorySlug });
            }}
            categoryId={categoryId}
          />
          <div className="relative">
            <ListingTagsField
              defaultValue={tagList}
              categorySlug={categorySlug}
              name="listing[tag_list]"
              onInput={linkState(this, 'tagList')}
            />
          </div>
          <ExpireDate
            defaultValue={expireDate}
            onChange={linkState(this, 'expireDate')}
          />
          {selectOrg}
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
        <ListingTagsField
          defaultValue={tagList}
          onInput={linkState(this, 'tagList')}
        />
        {selectOrg}
      </div>
    );
  }
}

ListingForm.propTypes = {
  listing: PropTypes.string.isRequired,
  categoriesForDetails: PropTypes.string.isRequired,
  categoriesForSelect: PropTypes.string.isRequired,
  organizations: PropTypes.string.isRequired,
};
