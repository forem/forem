import { h } from 'preact';
import PropTypes from 'prop-types';

const ModFaqSection = ({ email }) => {
  return (
    <div className="crayons-card grid gap-2 p-4 faq-section">
      <p className="contact-details">
        Questions about Connect Channel moderation? Contact
        <a
          href={`mailto:${email}`}
          target="_blank"
          rel="noopener noreferrer"
          className="mx-2 url-link"
        >
          {email}
        </a>
      </p>
    </div>
  );
};

ModFaqSection.propTypes = {
  email: PropTypes.string.isRequired,
};

export default ModFaqSection;
