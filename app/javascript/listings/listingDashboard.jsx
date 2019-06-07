import { h, Component } from 'preact';
import { ListingRow } from './dashboard/listingRow';

export class ListingDashboard extends Component {
  state = {
    listings: [],
    orgListings: [],
    orgs: [],
    userCredits: 0,
    currentUserId: null,
    selectedListings: "user",
  }

  componentWillMount() {
    const t = this;
    const container = document.getElementById('classifieds-listings-dashboard')
    let listings = [];
    let orgs = [];
    let orgListings = [];
    listings = JSON.parse(container.dataset.listings);
    orgs = JSON.parse(container.dataset.orgs);
    orgListings = JSON.parse(container.dataset.orglistings);
    const userCredits = container.dataset.usercredits;
    t.setState({ listings, orgListings, orgs, userCredits });
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
    const { listings, orgListings, userCredits, orgs, selectedListings } = this.state

    const showListings = (selected, userListings, organizationListings) => {
      if (selected === "user") {
        return userListings.map(listing => <ListingRow listing={listing} />)
      }
        return organizationListings.map(listing => (listing.organization_id === selected) ? <ListingRow listing={listing} /> : '')

    }

    const orgButtons = orgs.map(org => (
      <span onClick={() => this.setState({selectedListings: org.id})}>
        {org.name}
        {' '}
      </span>
    ))

    return (
      <div className="dashboard-listings-container">
        <span onClick={() => this.setState({selectedListings: "user"})}>Personal</span>
        {orgButtons}
        <div className="dashboard-listings-actions">
          <div className="dashboard-listings-info">
            <h3>Listings</h3>
            <h4>
Listings Made:
              {listings.length}
            </h4>
            <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          </div>
          <div className="dashboard-listings-info">
            <h3>Credits</h3>
            <h4>
Credits Available:
              {userCredits}
            </h4>
            <a href="/credits/purchase" data-no-instant>Buy More Credits</a>
          </div>
        </div>
        <div className="dashboard-listings-view">
          {showListings(selectedListings, listings, orgListings)}
        </div>
      </div>
    )
  }
}
