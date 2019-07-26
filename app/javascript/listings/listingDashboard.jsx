import { h, Component } from 'preact';
import { ListingRow } from './dashboard/listingRow';

export class ListingDashboard extends Component {
  state = {
    listings: [],
    orgListings: [],
    orgs: [],
    userCredits: 0,
    selectedListings: 'user',
  };

  componentDidMount() {
    const t = this;
    const container = document.getElementById('classifieds-listings-dashboard');
    let listings = [];
    let orgs = [];
    let orgListings = [];
    listings = JSON.parse(container.dataset.listings);
    orgs = JSON.parse(container.dataset.orgs);
    orgListings = JSON.parse(container.dataset.orglistings);
    const userCredits = container.dataset.usercredits;
    t.setState({ listings, orgListings, orgs, userCredits });
  }

  render() {
    const {
      listings,
      orgListings,
      userCredits,
      orgs,
      selectedListings,
    } = this.state;

    const showListings = (selected, userListings, organizationListings) => {
      return selected === 'user'
        ? userListings.map(listing => <ListingRow listing={listing} />)
        : organizationListings.map(listing =>
            listing.organization_id === selected ? (
              <ListingRow listing={listing} />
            ) : (
              ''
            ),
          );
    };
    
    const sortListings = (event) => {
      const sortedListings = listings.sort((a,b) => (a[event.target.value] > b[event.target.value]) ? -1 : 1)
      this.setState({listings: sortedListings});
    }

    const sortingDropdown = (
      <div class="dashboard-listings-sorting">
        <select onChange={sortListings} >
          <option value="created_at" selected="selected">Recently Created</option>
          <option value="bumped_at">Recently Bumped</option>
        </select>
      </div>
    );

    const orgButtons = orgs.map(org => (
      <span
        onClick={() => this.setState({ selectedListings: org.id })}
        className={`rounded-btn ${selectedListings === org.id ? 'active' : ''}`}
      >
        {org.name}
      </span>
    ));

    const listingLength = (selected, userListings, organizationListings) => {
      return selected === 'user' ? (
        <h4>Listings Made: {userListings.length}</h4>
      ) : (
        <h4>
          Listings Made:{' '}
          {
            organizationListings.filter(
              listing => listing.organization_id === selected,
            ).length
          }
        </h4>
      );
    };

    const creditCount = (selected, userCreds, organizations) => {
      return selected === 'user' ? (
        <h4>Credits Available: {userCredits}</h4>
      ) : (
        <h4>
          Credits Available:{' '}
          {organizations.find(org => org.id === selected).unspent_credits_count}
        </h4>
      );
    };

    return (
      <div className="dashboard-listings-container">
        <span
          onClick={() => this.setState({ selectedListings: 'user' })}
          className={`rounded-btn ${
            selectedListings === 'user' ? 'active' : ''
          }`}
        >
          Personal
        </span>
        {orgButtons}
        <div className="dashboard-listings-header-wrapper">
          <div className="dashboard-listings-header">
            <h3>Listings</h3>
            {listingLength(selectedListings, listings, orgListings)}
            <a href="/listings/new">Create a Listing</a>
          </div>
          <div className="dashboard-listings-header">
            <h3>Credits</h3>
            {creditCount(selectedListings, userCredits, orgs)}
            <a href="/credits/purchase" data-no-instant>
              Buy Credits
            </a>
          </div>
        </div>
        {sortingDropdown}
        <div className="dashboard-listings-view">
          {showListings(selectedListings, listings, orgListings)}
        </div>
      </div>
    );
  }
}
