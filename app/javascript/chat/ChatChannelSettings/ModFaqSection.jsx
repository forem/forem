import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

export const ModFaqSection = ({ currentMembershipRole }) => {
  if (currentMembershipRole === 'member') {
    return null;
  }

  return (
    <div className="crayons-card grid gap-2 p-4 faq-section">
      <p className="contact-details">
        {i18next.t('chat.settings.questions')}
        <a
          href="/contact"
          target="_blank"
          rel="noopener noreferrer"
          className="mx-2 url-link"
        >
          {i18next.t('chat.settings.contact')}
        </a>
      </p>
    </div>
  );
};

ModFaqSection.propTypes = {
  currentMembershipRole: PropTypes.string.isRequired,
};
