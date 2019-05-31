import { h, Component } from 'preact';
import { ListingRow } from './dashboard/listingRow';

export class ListingDashboard extends Component {
  state = {
    listings: [],
    user_credits: 0,
    org_credits: 0,
  }

  componentWillMount() {
    const t = this;
    const container = document.getElementById('classifieds-listings-dashboard')
    let listings = [];
    listings = JSON.parse(container.dataset.listings)
    t.setState({ listings });
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
    const { listings } = this.state
    const userListings = listings.map(listing => (
      <ListingRow
        listing = {listing}
      />
    ))

    return (
      <div className="dashboard-listings-container">
        <div className="dashboard-listings-actions">
          {listings.length}
          <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          {/* Show number of user / org credits available */}
          {/* Link to purchase credits */}
          <a href="/credits/purchase" data-no-instant>Buy More Credits</a>
        </div>
        <div className="dashboard-listings-view"> // show all listings here in list form
          {userListings}
        </div>
      </div>
    )
  }
}
