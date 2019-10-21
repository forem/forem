import { h, Component } from 'preact/dist/preact';
import PropTypes from 'prop-types';

export default class Endorsements extends Component {
  static reloadPage() {
    window.location.reload(true);
  }

  static handleDeleteEndorsement(endorsement) {
    if (window.confirm('Delete your endorsement?')) {
      const url = `/endorsements/${endorsement.id}.json`;
      const method = 'DELETE';

      fetch(url, {
        method,
        headers: Endorsements.getFetchHeaders(),
        credentials: 'same-origin',
      }).then(Endorsements.reloadPage);
    }
  }

  constructor(props) {
    super(props);

    this.state = {
      message: '',
      endorsementBeingEdited: null,
    };

    this.handleOpenModal = this.handleOpenModal.bind(this);
    this.handleCancelEndorsement = this.handleCancelEndorsement.bind(this);
    this.handleSubmitEndorsement = this.handleSubmitEndorsement.bind(this);
    this.handleDraftingMessage = this.handleDraftingMessage.bind(this);
  }

  setStateWithUpdate(newState) {
    this.setState(newState);
    this.forceUpdate();
  }

  static getFetchHeaders() {
    const metaTag = document.querySelector("meta[name='csrf-token']");

    return {
      'X-CSRF-Token': metaTag.getAttribute('content'),
    };
  }

  handleOpenModal(e) {
    const { onOpenModal, listing } = this.props;
    onOpenModal(e, listing);
  }

  handleCancelEndorsement(e) {
    e.preventDefault();

    const { closeAddEndorsement } = this.props;

    closeAddEndorsement();

    this.setStateWithUpdate({
      message: '',
      endorsementBeingEdited: null,
    });
  }

  handleEditEndorsement(endorsement) {
    this.setStateWithUpdate({
      endorsementBeingEdited: endorsement,
    });
  }

  handleDraftingMessage(e) {
    e.preventDefault();
    const message = e.target.value;
    const { endorsementBeingEdited } = this.state;

    this.setStateWithUpdate({
      message,
      endorsementBeingEdited:
        endorsementBeingEdited !== null
          ? Object.assign({}, endorsementBeingEdited, { message })
          : null,
    });
  }

  handleSubmitEndorsement(e) {
    e.preventDefault();

    const { listing } = this.props;
    const { message, endorsementBeingEdited } = this.state;

    if (message.replace(/\s/g, '').length === 0) {
      return;
    }

    const formData = new FormData();
    formData.append('message', message);
    formData.append('classified_listing_id', listing.id);

    const isEditing = endorsementBeingEdited !== null;
    const url = isEditing
      ? `/endorsements/${endorsementBeingEdited.id}.json`
      : '/endorsements.json';
    const method = isEditing ? 'PATCH' : 'POST';

    fetch(url, {
      method,
      headers: Endorsements.getFetchHeaders(),
      body: formData,
      credentials: 'same-origin',
    }).then(Endorsements.reloadPage);
  }

  buildEndorsementsForListings() {
    const { endorsements } = this.props;
    const NUMBER_OF_PROFILE_IMAGES_TO_SHOW = 3;

    return (
      <button
        type="button"
        onClick={this.handleOpenModal}
        className="single-classified-listing-endorsements-open-modal-button"
      >
        <div className="single-classified-listing-endorsement-profile-images">
          {endorsements
            .slice(0, NUMBER_OF_PROFILE_IMAGES_TO_SHOW)
            .map(endorsement => (
              <img
                alt={endorsement.name}
                className="single-classified-listing-endorsement-profile-image"
                src={endorsement.profile_image_35}
              />
            ))}
        </div>
        <span className="single-classified-listing-endorsement-endorsment-count">
          {endorsements.length}
          {' '}
endorsements
        </span>
      </button>
    );
  }

  buildEndorsementsForOpenListingModal() {
    const { endorsements } = this.props;
    const { endorsementBeingEdited } = this.state;

    return (
      <div className="single-classified-listing-endorsements--opened">
        {endorsements.map(endorsement => {
          if (
            endorsementBeingEdited !== null &&
            endorsementBeingEdited.id === endorsement.id
          ) {
            return this.buildAddEditEndorsementsForm();
          }
          return this.buildEndorsement(endorsement);
        })}
      </div>
    );
  }

  buildAddEditEndorsementsForm() {
    const { endorsementBeingEdited, message } = this.state;

    const isEditing = endorsementBeingEdited !== null;

    return (
      <form className="listings-add-endorsement">
        <p>
          <b>
            {isEditing ? 'Edit' : 'Add'}
            {' '}
Endorsement
          </b>
        </p>
        <textarea
          value={isEditing ? endorsementBeingEdited.message : message}
          onKeyUp={this.handleDraftingMessage}
          rows="2"
          cols="70"
          placeholder="Enter your endorsement here..."
        />
        <button
          type="button"
          onClick={this.handleCancelEndorsement}
          className="cancel-button cta"
        >
          CANCEL
        </button>
        <button
          type="button"
          onClick={this.handleSubmitEndorsement}
          className="submit-button cta"
        >
          SUBMIT
        </button>
        <p>
          <em>
            All endorsments 
            {' '}
            <b>must</b>
            {' '}
abide by the
            {' '}
            <a href="/code-of-conduct">code of conduct</a>
          </em>
        </p>
      </form>
    );
  }

  buildEndorsement(endorsement) {
    const { currentUserId } = this.props;

    return (
      <div className="single-classified-listing-endorsement">
        <a href={`/${endorsement.username}`}>
          <img
            alt={`Visit ${endorsement.name}'s profile`}
            className="single-classified-listing-endorsement-profile-image"
            src={endorsement.profile_image_35}
          />
        </a>
        <span className="single-classified-listing-endorsement-message-container">
          <div className="single-classified-listing-endorsement-message">
            {endorsement.message}
          </div>
          {endorsement.user_id === currentUserId && (
            <div className="single-classified-listing-endorsement-buttons">
              <button
                type="button"
                onClick={() => this.handleEditEndorsement(endorsement)}
              >
                edit
              </button>
              <button
                type="button"
                onClick={() =>
                  Endorsements.handleDeleteEndorsement(endorsement)
                }
              >
                ・ delete
              </button>
            </div>
          )}
        </span>
      </div>
    );
  }

  render() {
    const { shouldShowAddEndorsement, isOpen } = this.props;

    return (
      <div>
        {shouldShowAddEndorsement ? this.buildAddEditEndorsementsForm() : null}
        <div className="single-classified-listing-endorsements">
          {isOpen
            ? this.buildEndorsementsForOpenListingModal()
            : this.buildEndorsementsForListings()}
        </div>
      </div>
    );
  }
}

Endorsements.propTypes = {
  listing: PropTypes.shape({
    id: PropTypes.number.isRequired,
  }).isRequired,
  isOpen: PropTypes.bool.isRequired,
  currentUserId: PropTypes.number.isRequired,
  endorsements: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      message: PropTypes.string.isRequired,
      profile_image_35: PropTypes.string.isRequired,
    }),
  ).isRequired,
  shouldShowAddEndorsement: PropTypes.bool.isRequired,
  closeAddEndorsement: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
};
