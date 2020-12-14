import { h } from 'preact';
import PropTypes from 'prop-types';
import { Dropdown, Button } from '@crayons';

export const Options = ({
  passedData: {
    published = false,
    allSeries = [],
    canonicalUrl = '',
    series = '',
  },
  onSaveDraft,
  onConfigChange,
  toggleMoreConfig,
  moreConfigShowing,
}) => {
  let publishedField = '';
  let existingSeries = '';

  if (allSeries.length > 0) {
    const seriesNames = allSeries.map((name) => {
      return <option value={name}>{name}</option>;
    });
    existingSeries = (
      <div className="crayons-field__description">
        Existing series:
        {` `}
        <select
          value=""
          name="series"
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
        <Button variant="danger" onClick={onSaveDraft}>
          Unpublish post
        </Button>
      </div>
    );
  }
  return (
    <Dropdown
      className={
        moreConfigShowing &&
        'inline-block bottom-100 left-2 s:left-0 right-2 s:left-auto'
      }
      style={{ zIndex: 100 }}
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
      <Button className="w-100" data-content="exit" onClick={toggleMoreConfig}>
        Done
      </Button>
    </Dropdown>
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
  toggleMoreConfig: PropTypes.func.isRequired,
  moreConfigShowing: PropTypes.bool.isRequired,
};

Options.displayName = 'Options';
