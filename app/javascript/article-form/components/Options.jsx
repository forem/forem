import { h } from 'preact';
import PropTypes from 'prop-types';
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
    allSeries = [],
    canonicalUrl = '',
    series = '',
  },
  onSaveDraft,
  onConfigChange,
}) => {
  let publishedField = '';
  let existingSeries = '';

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
  return (
    <div className="s:relative">
      <Button
        id="post-options-btn"
        icon={CogIcon}
        title="Post options"
        aria-label="Post options"
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
    allSeries: PropTypes.array.isRequired,
    canonicalUrl: PropTypes.string.isRequired,
    series: PropTypes.string.isRequired,
  }).isRequired,
  onSaveDraft: PropTypes.func.isRequired,
  onConfigChange: PropTypes.func.isRequired,
};

Options.displayName = 'Options';
