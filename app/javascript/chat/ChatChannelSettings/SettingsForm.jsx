import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

/**
 *
 * This component render the setting for for the chat channel. This section is only available for mod users
 *
 *
 * @param {object} props
 * @param {string} props.channelDescription
 * @param {function} props.handleDescriptionChange
 * @param {string} props.channelDiscoverable
 * @param {function} props.handleChannelDiscoverableStatus
 * @param {function} props.handleChannelDescriptionChanges
 *
 *
 * @component
 *
 * @example
 *
 * <SettingsFrom
 *  channelDescription={channelDescription}
 *  handleDescriptionChange={handleDescriptionChange}
 *  channelDiscoverable={channelDiscoverable}
 *  handleChannelDiscoverableStatus={handleChannelDiscoverableStatus}
 *  handleChannelDescriptionChanges={handleChannelDescriptionChanges}
 * />
 *
 */
export default function SettingsFrom({
  channelDescription,
  handleDescriptionChange,
  channelDiscoverable,
  handleChannelDiscoverableStatus,
  handleChannelDescriptionChanges,
}) {
  return (
    <div
      data-testid="settings-form"
      className="crayons-card p-4 grid gap-2 mb-4 settings-section"
    >
      <h3>Channel Settings</h3>
      <div className="crayons-field">
        <label
          className="crayons-field__label"
          htmlFor="chat_channel_description"
        >
          Description
        </label>
        <textarea
          className="crayons-textfield"
          name="description"
          id="chat_channel_description"
          value={channelDescription}
          onChange={handleDescriptionChange}
        />
      </div>
      <div className="crayons-field crayons-field--checkbox">
        <input
          type="checkbox"
          id="c2"
          className="crayons-checkbox"
          checked={channelDiscoverable}
          onChange={handleChannelDiscoverableStatus}
        />
        <label htmlFor="c2" className="crayons-field__label">
          Channel Discoverable
        </label>
      </div>
      <div>
        <Button type="submit" onClick={handleChannelDescriptionChanges}>
          Submit
        </Button>
      </div>
    </div>
  );
}

SettingsFrom.propTypes = {
  channelDescription: PropTypes.string.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
  handleChannelDiscoverableStatus: PropTypes.func.isRequired,
  handleChannelDescriptionChanges: PropTypes.func.isRequired,
  channelDiscoverable: PropTypes.bool.isRequired,
};
