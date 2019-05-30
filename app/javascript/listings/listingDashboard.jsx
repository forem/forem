import { h, Component } from 'preact';
import { ListingRow } from './listingRow';

export default class ListingForm extends Component {
  state = {
    listings: [],
    user_credits: 0,
    org_credits: 0,

  }

  componentWillMount() {

  }

  componentWillUnmount() {

  }

  render() {
    const userListings = listings.map(listing => (
      <ListingRow
        listing = {listing}
      />
    ))

    return (
      <div className="dashboard__listings__container">
        <div>
          // display number of listings; active and inactive
          <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          // display credit counts
          // button for buying credits
        </div>
        <div> // show all listings here in list form
          {userListings}
        </div>
      </div>
    )
  }
}
