import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';

// const ImageManagement = ({ onExit }) => (
export default class MoreConfig extends Component {
  constructor(props) {
    super(props);
    // this.state = {insertionImageUrl: null}
  }

  handleSeriesButtonClick = e => {
    e.preventDefault();
    this.props.onConfigChange(e);
  };

  render() {
    const { onExit, passedData, onSaveDraft } = this.props;
    let publishedField = '';
    let seriesTip = (
      <small>
        Will this post be part of a series? Give the series a unique name.
        (Series visible once it has multiple posts)
      </small>
    );
    if (passedData.allSeries.length > 0) {
      const seriesNames = passedData.allSeries.map(name => {
        return (
          <button
            name="series"
            onClick={this.props.onConfigChange}
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
    if (passedData.published) {
      publishedField = (
        <div>
          <h4>Danger Zone</h4>
          <button onClick={onSaveDraft}>Unpublish Post</button>
        </div>
      );
    }
    return (
      <div className="articleform__overlay">
        <h3>Additional Config/Settings</h3>
        <button
          className="articleform__exitbutton"
          data-content="exit"
          onClick={onExit}
        >
          ×
        </button>
        <div>
          <label>Canonical URL</label>
          <input
            type="text"
            value={passedData.canonicalUrl}
            name="canonicalUrl"
            onKeyUp={this.props.onConfigChange}
          />
        </div>
        <small>
          Change meta tag <code>canonical_url</code> if this post was first
          published elsewhere (like your own blog)
        </small>
        <div>
          <label>Series Name</label>
          <input
            type="text"
            value={passedData.series}
            name="series"
            onKeyUp={this.props.onConfigChange}
          />
        </div>
        {seriesTip}
        <div>
          <button className="articleform__donebutton" onClick={onExit}>
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
};
