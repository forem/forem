import PropTypes from 'prop-types';
import { h, Component, createRef } from 'preact';
import listingPropTypes from './listingPropTypes';
import { Button } from '@crayons';

const Icon = () => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      fill-rule="evenodd"
      clip-rule="evenodd"
      d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"
    />
  </svg>
);

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

  handleClickOutside = (e) => {
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
      <div
        className="single-listing__dropdown absolute right-0 top-0"
        ref={this.componentRef}
      >
        <Button
          variant="ghost"
          contentType="icon"
          tagName="button"
          aria-label="Toggle dropdown menu"
          icon={Icon}
          onClick={this.toggleMenu}
        />
        <div
          className={`crayons-dropdown absolute right-0 top-100 p-1 ${
            isOpen ? 'block' : ''
          }`}
        >
          {isOwner ? (
            <a href={editUrl} className="crayons-link crayons-link--block">
              Edit
            </a>
          ) : (
            <a href={reportUrl} className="crayons-link crayons-link--block">
              Report Abuse
            </a>
          )}
        </div>
      </div>
    );
  }
}

export default DropdownMenu;
