import { h } from 'preact';
import PropTypes from 'prop-types';
import moment from 'moment';
import { Dropdown, ButtonNew as Button } from '@crayons';
import CogIcon from '@images/cog.svg';

/**
 * Component comprising a trigger button and dropdown with additional post options.
 *
 * @param {Object} props
 * @param {Object} props.passedData The current post options data
 * @param {Function} props.onSaveDraft Callback for when the post draft is saved
 * @param {Function} props.onConfigChange Callback for when the config options have changed
 */

export const Options = ({
  passedData: {
    published = false,
    publishedAtDate = '',
    publishedAtTime = '',
    publishedAtWas = '',
    timezone = Intl.DateTimeFormat().resolvedOptions().timeZone,
    allSeries = [],
    canonicalUrl = '',
    series = '',
  },
  schedulingEnabled,
  onSaveDraft,
  onConfigChange,
  previewLoading,
}) => {
  let publishedField = '';
  let existingSeries = '';
  let publishedAtField = '';

  const wasScheduled = moment(publishedAtWas) > moment();
  const readonlyPublishedAt = published && !wasScheduled;

  if (allSeries.length > 0) {
    const seriesNames = allSeries.map((name, index) => {
      return (
        <option key={`series-${index}`} value={name}>
          {name}
        </option>
      );
    });
    existingSeries = (
      <div className="crayons-field__description">
        Existing series:
        {` `}
        <select
          value=""
          name="series"
          className="crayons-select"
          onInput={onConfigChange}
          required
          aria-label="Select one of the existing series"
        >
          <option value="" disabled>
            Select...
          </option>
          {seriesNames}
        </select>
      </div>
    );
  }

  if (published) {
    if (wasScheduled) {
      publishedField = (
        <div data-testid="options__danger-zone" className="crayons-field mb-6">
          <Button
            className="c-btn c-btn--secondary w-100"
            variant="primary"
            onClick={onSaveDraft}
          >
            Convert to a Draft
          </Button>
        </div>
      );
    } else {
      publishedField = (
        <div data-testid="options__danger-zone" className="crayons-field mb-6">
          <div className="crayons-field__label color-accent-danger">
            Danger Zone
          </div>
          <Button variant="primary" destructive onClick={onSaveDraft}>
            Unpublish post
          </Button>
        </div>
      );
    }
  }

  if (schedulingEnabled && !readonlyPublishedAt) {
    const currentDate = moment().format('YYYY-MM-DD');
    publishedAtField = (
      <div className="crayons-field mb-6">
        <label htmlFor="publishedAtDate" className="crayons-field__label">
          Schedule Publication
        </label>
        <input
          aria-label="Schedule publication date"
          type="date"
          min={currentDate}
          value={publishedAtDate} // ""
          className="crayons-textfield"
          name="publishedAtDate"
          onChange={onConfigChange}
          id="publishedAtDate"
          placeholder="..."
        />
        <input
          aria-label="Schedule publication time"
          type="time"
          value={publishedAtTime} // "18:00"
          className="crayons-textfield"
          name="publishedAtTime"
          onChange={onConfigChange}
          id="publishedAtTime"
          placeholder="..."
        />
        <input
          type="hidden"
          value={timezone} // "Asia/Magadan"
          className="crayons-textfield"
          name="timezone"
          id="timezone"
          placeholder="..."
        />
      </div>
    );
  }

  return (
    <div className="s:relative">
      <Button
        id="post-options-btn"
        icon={CogIcon}
        title="Post options"
        aria-label="Post options"
        disabled={previewLoading}
      />

      <Dropdown
        triggerButtonId="post-options-btn"
        dropdownContentId="post-options-dropdown"
        dropdownContentCloseButtonId="post-options-done-btn"
        className="reverse left-2 s:left-0 right-2 s:left-auto p-4"
      >
        <h3 className="mb-6">Post options</h3>
        <div className="crayons-field mb-6">
          <label htmlFor="canonicalUrl" className="crayons-field__label">
            Canonical URL
          </label>
          <p className="crayons-field__description">
            Change meta tag
            {` `}
            <code>canonical_url</code>
            {` `}
            if this post was first published elsewhere (like your own blog).
          </p>
          <input
            type="text"
            value={canonicalUrl}
            className="crayons-textfield"
            placeholder="https://yoursite.com/post-title"
            name="canonicalUrl"
            onKeyUp={onConfigChange}
            id="canonicalUrl"
          />
        </div>
        {publishedAtField}
        <div className="crayons-field mb-6">
          <label htmlFor="series" className="crayons-field__label">
            Series
          </label>
          <p className="crayons-field__description">
            Will this post be part of a series? Give the series a unique name.
            (Series visible once it has multiple posts)
          </p>
          <input
            type="text"
            value={series}
            className="crayons-textfield"
            name="series"
            onKeyUp={onConfigChange}
            id="series"
            placeholder="..."
          />
          {existingSeries}
        </div>
        {publishedField}
        <Button
          id="post-options-done-btn"
          className="w-100"
          data-content="exit"
          variant="secondary"
        >
          Done
        </Button>
      </Dropdown>
    </div>
  );
};

Options.propTypes = {
  passedData: PropTypes.shape({
    published: PropTypes.bool.isRequired,
    publishedAtDate: PropTypes.string.isRequired,
    publishedAtTime: PropTypes.string.isRequired,
    publishedAtWas: PropTypes.string.isRequired,
    timezone: PropTypes.string.isRequired,
    allSeries: PropTypes.array.isRequired,
    canonicalUrl: PropTypes.string.isRequired,
    series: PropTypes.string.isRequired,
  }).isRequired,
  schedulingEnabled: PropTypes.bool.isRequired,
  onSaveDraft: PropTypes.func.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  previewLoading: PropTypes.bool.isRequired,
};

Options.displayName = 'Options';
