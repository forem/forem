import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';
import { Button } from '@crayons';

export const PersonalSettings = ({
  handlePersonChannelSetting,
  showGlobalBadgeNotification,
  updateCurrentMembershipNotificationSettings,
}) => {
  return (
    <div className="crayons-card p-4 grid gap-2 mb-4 personl-settings">
      <h3>{i18next.t('chat.settings.personal')}</h3>
      <h4>{i18next.t('chat.settings.notifications')}</h4>
      <div className="crayons-field crayons-field--checkbox">
        <input
          type="checkbox"
          id="c3"
          className="crayons-checkbox"
          checked={showGlobalBadgeNotification}
          onChange={handlePersonChannelSetting}
        />
        <label htmlFor="c3" className="crayons-field__label">
          {i18next.t('chat.settings.receive')}
        </label>
      </div>
      <div>
        <Button
          type="submit"
          onClick={updateCurrentMembershipNotificationSettings}
        >
          {i18next.t('chat.settings.update')}
        </Button>
      </div>
    </div>
  );
};

PersonalSettings.propTypes = {
  updateCurrentMembershipNotificationSettings: PropTypes.func.isRequired,
  showGlobalBadgeNotification: PropTypes.bool.isRequired,
  handlePersonChannelSetting: PropTypes.func.isRequired,
};
