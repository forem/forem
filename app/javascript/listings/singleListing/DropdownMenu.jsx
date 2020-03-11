import PropTypes from 'prop-types';
import { h, Component, createRef } from 'preact';
// eslint-disable-next-line import/no-unresolved
import ThreeDotsIcon from 'images/three-dots.svg';
import listingPropTypes from './listingPropTypes';

const MenuButton = ({ onClick }) => (
  <button
    type="button"
    className="dropdown-btn"
    aria-label="Toggle dropdown menu"
    onClick={onClick}
  >
    <img
      src={ThreeDotsIcon}
      className="dropdown-icon"
      alt="Dropdown menu icon"
    />
  </button>
);

MenuButton.propTypes = {
  onClick: PropTypes.func.isRequired,
};

class DropdownMenu extends Component {
  componentRef = createRef();

  static propTypes = {
    isOwner: PropTypes.bool.isRequired,
    listing: listingPropTypes.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      isOpen: false,
    };
  }

  toggleMenu = () => {
    const { isOpen } = this.state;
    this.setState({ isOpen: !isOpen }, this.addOrRemoveClickOutsideHandler);
  };

  addOrRemoveClickOutsideHandler = () => {
    const { isOpen } = this.state;
    return isOpen
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
    const { listing, isOwner } = this.props;
    const { isOpen } = this.state;
    const { id, category, slug } = listing;
    const editUrl = `/listings/${id}/edit`;
    const reportUrl = `/report-abuse?url=https://dev.to/listings/${category}/${slug}`;

    return (
      <div className="dropdown-menu" ref={this.componentRef}>
        <MenuButton onClick={this.toggleMenu} />
        <div className="dropdown">
          <div
            className={['dropdown-content', isOpen ? 'showing' : ''].join(' ')}
          >
            {isOwner ? (
              <a href={editUrl} className="classified-listing-edit-button">
                Edit
              </a>
            ) : (
              <a href={reportUrl}>Report Abuse</a>
            )}
          </div>
        </div>
      </div>
    );
  }
}

export default DropdownMenu;
