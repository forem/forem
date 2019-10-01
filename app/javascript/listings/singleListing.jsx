import PropTypes from 'prop-types';
import { h, Component, createRef } from 'preact';
import ThreeDotsIcon from 'images/three-dots.svg';

export class SingleListing extends Component {
  static propTypes = {
    listing: PropTypes.objectOf(PropTypes.object).isRequired,
    onAddTag: PropTypes.func.isRequired,
    onOpenModal: PropTypes.func.isRequired,
    onChangeCategory: PropTypes.func.isRequired,
    isOpen: PropTypes.bool.isRequired,
    currentUserId: PropTypes.number,
  };

  static defaultProps = {
    currentUserId: null,
  };

  componentRef = createRef();

  constructor(props) {
    super(props);

    this.state = {
      isMenuOpen: false,
    };
  }

  getTagLinks = () => {
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
  };

  toggleMenu = () => {
    const { isMenuOpen } = this.state;
    this.setState(
      { isMenuOpen: !isMenuOpen },
      this.addOrRemoveClickOutsideHandler,
    );
  };

  addOrRemoveClickOutsideHandler = () => {
    const { isMenuOpen } = this.state;
    return isMenuOpen
      ? document.addEventListener('mousedown', this.handleClickOutside)
      : document.removeEventListener('mousedown', this.handleClickOutside);
  };

  handleClickOutside = e => {
    if (
      this.componentRef.current &&
      !this.componentRef.current.contains(e.target)
    ) {
      this.toggleMenu();
    }
  };

  render() {
    const {
      listing,
      currentUserId,
      onChangeCategory,
      onOpenModal,
      isOpen,
    } = this.props;
    const { isMenuOpen } = this.state;
    const locationText = listing.location ? (
      <a href={`/listings/?q=${listing.location}`}>
        {'・'}
        {listing.location}
      </a>
    ) : (
      ''
    );

    const definedClass = isOpen
      ? 'single-classified-listing single-classified-listing--opened'
      : 'single-classified-listing';

    return (
      <div
        ref={this.componentRef}
        className={definedClass}
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
            <button
              type="button"
              className="dropdown-btn"
              aria-label="Toggle dropdown menu"
              onClick={this.toggleMenu}
            >
              <img
                src={ThreeDotsIcon}
                className="dropdown-icon"
                alt="Dropdown menu icon"
              />
            </button>
            <div className="dropdown">
              <div
                className={[
                  'dropdown-content',
                  isMenuOpen ? 'showing' : '',
                ].join(' ')}
              >
                {currentUserId === listing.user_id ? (
                  <a
                    href={`/listings/${listing.id}/edit`}
                    className="classified-listing-edit-button"
                  >
                    Edit
                  </a>
                ) : (
                  <a
                    href={`/report-abuse?url=https://dev.to/listings/${listing.category}/${listing.slug}`}
                  >
                    Report Abuse
                  </a>
                )}
              </div>
            </div>
          </h3>
          <div
            className="single-classified-listing-body"
            dangerouslySetInnerHTML={{ __html: listing.processed_html }}
          />
          <div className="single-classified-listing-tags">
            {this.getTagLinks()}
          </div>
          <div className="single-classified-listing-author-info">
            <a
              href={`/listings/${listing.category}`}
              onClick={e => onChangeCategory(e, listing.category)}
              data-no-instant
            >
              {listing.category}
            </a>
            {locationText}
            {'・'}
            <a href={`/${listing.author.username}`}>{listing.author.name}</a>
          </div>
        </div>
      </div>
    );
  }
}
