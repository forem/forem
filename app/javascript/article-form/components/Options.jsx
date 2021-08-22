import { h } from 'preact';
import PropTypes from 'prop-types';
import { Dropdown, Button } from '@crayons';

const Icon = () => (
  <svg
    width="24"
    className="crayons-icon"
    height="24"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    aria-labelledby="75abcb76478519ca4eb9"
  >
    <title id="75abcb76478519ca4eb9">Post options</title>
    <path d="M12 1l9.5 5.5v11L12 23l-9.5-5.5v-11L12 1zm0 2.311L4.5 7.653v8.694l7.5 4.342 7.5-4.342V7.653L12 3.311zM12 16a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z" />
  </svg>
);

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
    textLang = '',
    allLangs = {},
  },
  onSaveDraft,
  onConfigChange,
}) => {
  let publishedField = '';
  let existingSeries = '';
  let existingLangs = '';

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

  if (Object.keys(allLangs).length > 0) {
    const mapper = (sorted) => {
      return sorted.map((a) => {
        const [code, name] = a;
        return (
          <option key={`textLang-${code}`} value={code}>
            {name} [{code}]
          </option>
        );
      });
    };
    const sorter = (a, b) => {
      return a[1].localeCompare(b[1], 'en-US');
    };
    const miscSet = {};
    const siteSet = {};
    const specSet = {};
    /*
      References:
      https://gist.github.com/traysr/2001377
      https://www.statista.com/statistics/262946/share-of-the-most-common-languages-on-the-internet/
    */
    const siteCodes = [
      'en',
      'en-us',
      'en-gb',
      'fr',
      'de',
      'pl',
      'nl',
      'fi',
      'sv',
      'it',
      'es',
      'pt',
      'ru',
      'pt-br',
      'es-mx',
      'zh-hans',
      'zh-hant',
      'ja',
      'ko',
      'ar',
      'id',
      'ms',
    ];
    const specCodes = ['mul', 'und', 'zxx'];
    const dropCodes = [];
    Object.entries(allLangs).forEach(([code, name]) => {
      if (siteCodes.includes(code)) {
        siteSet[code] = name;
      } else if (specCodes.includes(code)) {
        specSet[code.slice(0, 3)] = name;
      } else if (dropCodes.includes(code)) {
        // discard
      } else {
        miscSet[code] = name;
      }
    });
    existingLangs = (
      <div className="crayons-field__description">
        List of languages:
        {` `}
        <select
          value=""
          name="textLang"
          className="crayons-select"
          onInput={onConfigChange}
          required
          aria-label="You can select a language from the list"
        >
          <option value="" disabled>
            Quick select
          </option>
          <optgroup label="Common">
            {mapper(Object.entries(siteSet).sort(sorter))}
          </optgroup>
          <optgroup label="Specials">
            {mapper(Object.entries(specSet).sort(sorter))}
          </optgroup>
          <optgroup label="General">
            {mapper(Object.entries(miscSet).sort(sorter))}
          </optgroup>
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
    <div className="s:relative">
      <Button
        id="post-options-btn"
        variant="ghost"
        contentType="icon"
        icon={Icon}
        title="Post options"
      />

      <Dropdown
        triggerButtonId="post-options-btn"
        dropdownContentId="post-options-dropdown"
        dropdownContentCloseButtonId="post-options-done-btn"
        className="bottom-2 s:bottom-100 left-2 s:left-0 right-2 s:left-auto"
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
        <div className="crayons-field mb-6">
          <label htmlFor="textLang" className="crayons-field__label">
            Language
          </label>
          <p className="crayons-field__description">
            What language is the body text written in? Specify by language tag (
            <code>en-US</code>).
          </p>
          <input
            type="text"
            value={textLang}
            className="crayons-textfield"
            placeholder="en-GB-oed"
            name="textLang"
            onKeyUp={onConfigChange}
            id="textLang"
          />
          {existingLangs}
        </div>
        {publishedField}
        <Button
          id="post-options-done-btn"
          className="w-100"
          data-content="exit"
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
    textLang: PropTypes.string.isRequired,
    allLangs: PropTypes.object.isRequired,
  }).isRequired,
  onSaveDraft: PropTypes.func.isRequired,
  onConfigChange: PropTypes.func.isRequired,
};

Options.displayName = 'Options';
