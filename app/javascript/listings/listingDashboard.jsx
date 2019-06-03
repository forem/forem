import { h, Component } from 'preact';
import { ListingRow } from './dashboard/listingRow';

export class ListingDashboard extends Component {
  state = {
    listings: [],
    org_listings: [],
    user_credits: 0,
    currentUserId: null,
  }

  componentWillMount() {
    const t = this;
    const container = document.getElementById('classifieds-listings-dashboard')
    let listings = [];
    let org_listings = [];
    listings = JSON.parse(container.dataset.listings);
    org_listings = JSON.parse(container.dataset.orglistings);
    let user_credits = container.dataset.usercredits;
    t.setState({ listings, org_listings, user_credits });
    t.setUser()
  }

  componentWillUnmount() {

  }

  setUser = () => {
    const t = this;
    setTimeout(function() {
      if (window.currentUser && t.state.currentUserId === null) {
        t.setState({currentUserId: window.currentUser.id });
      }
    }, 300)
    setTimeout(function() {
      if (window.currentUser && t.state.currentUserId === null) {
        t.setState({currentUserId: window.currentUser.id });
      }
    }, 1000)
  }

  render() {
    const { listings, org_listings, user_credits, currentUserId } = this.state
    const userListings = listings.map(listing => (
      <ListingRow
        listing = {listing}
      />
    ));
    console.log(org_listings)
    const orgListings = org_listings.map(listing => (
      <ListingRow
        listing = {listing}
      />
    ));

    return (
      <div className="dashboard-listings-container">
        <div className="dashboard-listings-actions">
          <div className="dashboard-listings-info">
            <h3>Listings</h3>
            <h4> {currentUserId}: {listings.length}</h4>

            <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          </div>

          <div className="dashboard-listings-credit-info">
            <h3>Credits</h3>
            {/* Show number of user / org credits available */}
            {user_credits}
            <a href="/credits/purchase" data-no-instant>Buy More Credits for user</a>
            <a href="/credits/purchase?purchaser=organization" data-no-instant>Buy More Credits for organization</a>
          </div>
        </div>
        <div className="dashboard-listings-view"> // show all listings here in list form
          {userListings}
          {orgListings}
        </div>
      </div>
    )
  }
}
