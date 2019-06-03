import { h, Component } from 'preact';
import { ListingRow } from './dashboard/listingRow';

export class ListingDashboard extends Component {
  state = {
    listings: [],
    user_credits: 0,
    currentUserId: null,
  }

  componentWillMount() {
    const t = this;
    const container = document.getElementById('classifieds-listings-dashboard')
    let listings = [];
    listings = JSON.parse(container.dataset.listings)
    let user_credits = container.dataset.usercredits
    t.setState({ listings, user_credits });
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
    const { listings, user_credits } = this.state
    const userListings = listings.map(listing => (
      <ListingRow
        listing = {listing}
      />
    ))

    return (
      <div className="dashboard-listings-container">
        <div className="dashboard-listings-actions">
          <div className="dashboard-listings-info">
            <h3>Listings</h3>
            <h4> mariocsee: {listings.length}</h4>
            {/* info for orgs? */}
            <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          </div>

          <div className="dashboard-listings-credit-info">
            <h3>Credits</h3>
            {/* Show number of user / org credits available */}
            {user_credits}
            <a href="/credits/purchase" data-no-instant>Buy More Credits</a>
          </div>
        </div>
        <div className="dashboard-listings-view"> // show all listings here in list form
          {userListings}
        </div>
      </div>
    )
  }
}
