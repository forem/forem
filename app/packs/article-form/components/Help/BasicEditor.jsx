import { h } from 'preact';
import PropTypes from 'prop-types';

export const BasicEditor = ({ openModal }) => (
  <div
    data-testid="basic-editor-help"
    className="crayons-card crayons-card--secondary p-4 mb-6"
  >
    You are currently using the basic markdown editor that uses{' '}
    <a href="#frontmatter" onClick={() => openModal('frontmatterShowing')}>
      Jekyll front matter
    </a>
    . You can also use the <em>rich+markdown</em> editor you can find in{' '}
    <a href="/settings/customization">
      UX settings
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        className="crayons-icon"
        xmlns="http://www.w3.org/2000/svg"
        role="img"
        aria-labelledby="c038a36b2512ed25db907e179ab45cfc"
        aria-hidden
      >
        <path d="M10.667 8v1.333H7.333v7.334h7.334v-3.334H16v4a.666.666 0 01-.667.667H6.667A.666.666 0 016 17.333V8.667A.667.667 0 016.667 8h4zM18 6v5.333h-1.333V8.275l-5.196 5.196-.942-.942 5.194-5.196h-3.056V6H18z" />
      </svg>
    </a>
    .
  </div>
);

BasicEditor.propTypes = {
  toggleModal: PropTypes.func.isRequired,
};
