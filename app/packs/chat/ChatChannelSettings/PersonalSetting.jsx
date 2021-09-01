import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const PersonalSettings = ({
  handlePersonChannelSetting,
  showGlobalBadgeNotification,
  updateCurrentMembershipNotificationSettings,
}) => {
  return (
    <div className="crayons-card p-4 grid gap-2 mb-4 personl-settings">
      <h3>Personal Settings</h3>
      <h4>Notifications</h4>
      <div className="crayons-field crayons-field--checkbox">
        <input
          type="checkbox"
          id="c3"
          className="crayons-checkbox"
          checked={showGlobalBadgeNotification}
          onChange={handlePersonChannelSetting}
        />
        <label htmlFor="c3" className="crayons-field__label">
          Receive Notifications for New Messages
        </label>
      </div>
      <div>
        <Button
          type="submit"
          onClick={updateCurrentMembershipNotificationSettings}
        >
          Submit
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
