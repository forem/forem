import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * This is a mod FAQ section, Where MOD user can ask questions
 *
 * @param {object} props
 * @param {string} currentMembershipRole
 *
 * @component
 *
 * @example
 *
 * <ModFaqSection
 *  currentMembershipRole={currentMembershipRole}
 * />
 *
 */

export default function ModFaqSection({ currentMembershipRole }) {
  if (currentMembershipRole === 'member') {
    return null;
  }

  return (
    <div className="crayons-card grid gap-2 p-4 faq-section">
      <p className="contact-details">
        Questions about Connect moderation?
        <a
          href={`/contact`}
          target="_blank"
          rel="noopener noreferrer"
          className="mx-2 url-link"
        >
          Contact site admins
        </a>
      </p>
    </div>
  );
}

ModFaqSection.propTypes = {
  currentMembershipRole: PropTypes.string.isRequired,
};
