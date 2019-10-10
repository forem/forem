import { h, Component } from 'preact';
import PropTypes from 'prop-types';

const TextField = ({ label, id, value, onKeyUp }) => {
  return (
    <div>
      <label htmlFor={id}>
        {label}
        <input type="text" value={value} name={id} onKeyUp={onKeyUp} id={id} />
      </label>
    </div>
  );
};

export default class MoreConfig extends Component {
  constructor(props) {
    super(props);
    // this.state = {insertionImageUrl: null}
  }

  handleSeriesButtonClick = e => {
    e.preventDefault();
    const { onConfigChange } = this.props;
    onConfigChange(e);
  };

  render() {
    const {
      onExit,
      passedData: {
        published = false,
        allSeries = [],
        canonicalUrl = '',
        series = '',
      },
      onSaveDraft,
      onConfigChange,
    } = this.props;
    let publishedField = '';
    let seriesTip = (
      <small>
        Will this post be part of a series? Give the series a unique name.
        (Series visible once it has multiple posts)
      </small>
    );
    if (allSeries.length > 0) {
      const seriesNames = allSeries.map(name => {
        return (
          <button
            type="button"
            name="series"
            onClick={onConfigChange}
            value={name}
          >
            {name}
          </button>
        );
      });
      seriesTip = (
        <small>
          Existing series:
          {seriesNames}
        </small>
      );
    }
    if (published) {
      publishedField = (
        <div>
          <h4>Danger Zone</h4>
          <button type="button" onClick={onSaveDraft}>
            Unpublish Post
          </button>
        </div>
      );
    }
    return (
      <div className="articleform__overlay">
        <h3>Additional Config/Settings</h3>
        <button
          type="button"
          className="articleform__exitbutton"
          data-content="exit"
          onClick={onExit}
        >
          ×
        </button>
        {TextField({
          label: 'Canonical URL',
          id: 'canonicalUrl',
          value: canonicalUrl,
          onKeyUp: onConfigChange,
        })}
        <small>
          Change meta tag
          <code>canonical_url</code>
          if this post was first published elsewhere (like your own blog)
        </small>
        {TextField({
          label: 'Series Name',
          id: 'series',
          value: series,
          onKeyUp: onConfigChange,
        })}
        {seriesTip}
        <div>
          <button
            type="button"
            className="articleform__donebutton"
            onClick={onExit}
          >
            Done
          </button>
        </div>
        {publishedField}
      </div>
    );
  }
}

MoreConfig.propTypes = {
  onExit: PropTypes.func.isRequired,
  passedData: PropTypes.objectOf().isRequired,
  onSaveDraft: PropTypes.func.isRequired,
  onConfigChange: PropTypes.func.isRequired,
};
