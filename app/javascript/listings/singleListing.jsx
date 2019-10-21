import PropTypes from 'prop-types';
import { Component, h } from 'preact';
import Endorsements from './elements/endorsements';

export default class SingleListing extends Component {
  constructor(props) {
    super(props);

    this.state = {
      shouldShowEndorsements: this.hasEndorsements(),
      shouldShowAddEndorsement: false,
    };

    this.openAddEndorsement = this.openAddEndorsement.bind(this);
    this.closeAddEndorsement = this.closeAddEndorsement.bind(this);
  }

  setStateWithUpdate(newState) {
    this.setState(newState);
    this.forceUpdate();
  }

  openAddEndorsement() {
    this.setStateWithUpdate({
      shouldShowEndorsements: true,
      shouldShowAddEndorsement: true,
    });
  }

  closeAddEndorsement() {
    this.setStateWithUpdate({
      shouldShowEndorsements: this.hasEndorsements(),
      shouldShowAddEndorsement: false,
    });
  }

  buildEditButton() {
    const { listing, currentUserId, isOpen } = this.props;
    const { shouldShowAddEndorsement } = this.state;

    if (currentUserId === listing.user_id) {
      return (
        <a
          href={`/listings/${listing.id}/edit`}
          className="classified-listing-edit-button"
        >
          ・edit
        </a>
      );
    }
    return (
      <span>
        <a
          href={`/report-abuse?url=https://dev.to/listings/${listing.category}/${listing.slug}`}
        >
          ・report abuse
        </a>
        {this.userCanEndorse() && isOpen && !shouldShowAddEndorsement && (
          <button type="button" onClick={this.openAddEndorsement}>
            ・add endorsement
          </button>
        )}
      </span>
    );
  }

  hasEndorsements() {
    const { listing } = this.props;

    const endorsements = listing.endorsement_list || [];
    return endorsements.length > 0;
  }

  buildTagLinks() {
    const { listing, onAddTag } = this.props;

    return listing.tag_list.map(tag => (
      <a
        href={`/listings?t=${tag}`}
        onClick={e => onAddTag(e, tag)}
        data-no-instant
      >
        {tag}
      </a>
    ));
  }

  buildLocationText() {
    const { listing } = this.props;

    if (listing.location) {
      return (
        <a href={`/listings/?q=${listing.location}`}>
・
          {listing.location}
        </a>
      );
    }
    return '';
  }

  userCanEndorse() {
    const { listing } = this.props;
    const { currentUserId } = this.props;

    const endorsements = listing.endorsement_list || [];
    const endorsementFromCurrentUser = endorsements.find(
      endorsement => endorsement.user_id === currentUserId,
    );
    const userHasNotEndorsedListing = endorsementFromCurrentUser === undefined;
    const userIsNotListingUser = listing.user_id !== currentUserId;

    return userIsNotListingUser && userHasNotEndorsedListing;
  }

  render() {
    const {
      listing,
      currentUserId,
      isOpen,
      onOpenModal,
      onChangeCategory,
    } = this.props;
    const { shouldShowAddEndorsement, shouldShowEndorsements } = this.state;

    return (
      <div
        className={
          isOpen
            ? 'single-classified-listing single-classified-listing--opened'
            : 'single-classified-listing'
        }
        id={`single-classified-listing-${listing.id}`}
      >
        <div className="listing-content">
          <h3>
            <a
              href={`/listings/${listing.category}/${listing.slug}`}
              data-no-instant
              onClick={e => onOpenModal(e, listing)}
              data-listing-id={listing.id}
            >
              {listing.title}
            </a>
          </h3>
          <div
            className="single-classified-listing-body"
            dangerouslySetInnerHTML={{ __html: listing.processed_html }}
          />
          <div className="single-classified-listing-tags">
            {this.buildTagLinks()}
          </div>
          <div className="single-classified-listing-author-info">
            <a
              href={`/listings/${listing.category}`}
              onClick={e => onChangeCategory(e, listing.category)}
              data-no-instant
            >
              {listing.category}
            </a>
            {this.buildLocationText()}
・
            <a href={`/${listing.author.username}`}>{listing.author.name}</a>
            {this.buildEditButton()}
          </div>
          {shouldShowEndorsements && (
            <Endorsements
              isOpen={isOpen}
              onOpenModal={onOpenModal}
              currentUserId={currentUserId}
              listing={listing}
              endorsements={listing.endorsement_list || []}
              shouldShowAddEndorsement={shouldShowAddEndorsement}
              closeAddEndorsement={this.closeAddEndorsement}
            />
          )}
        </div>
      </div>
    );
  }
}

SingleListing.propTypes = {
  listing: PropTypes.shape({
    id: PropTypes.number.isRequired,
    user_id: PropTypes.number.isRequired,
    title: PropTypes.string.isRequired,
    slug: PropTypes.string.isRequired,
    location: PropTypes.string,
    category: PropTypes.string,
    tag_list: PropTypes.arrayOf(PropTypes.string.isRequired),
    processed_html: PropTypes.string,
    endorsement_list: PropTypes.arrayOf({
      id: PropTypes.number.isRequired,
    }),
    author: PropTypes.shape({
      username: PropTypes.string.isRequired,
      name: PropTypes.string,
    }),
  }).isRequired,
  tag_list: PropTypes.arrayOf(PropTypes.string).isRequired,
  onAddTag: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  isOpen: PropTypes.bool.isRequired,
  currentUserId: PropTypes.number.isRequired,
};
