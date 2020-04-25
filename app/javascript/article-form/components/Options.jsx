import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Dropdown, Button } from '@crayons';

export class Options extends Component {
  handleSeriesButtonClick = (e) => {
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
      visible
    } = this.props;

    let publishedField = '';
    let existingSeries = '';
    
    if (allSeries.length > 0) {
      const seriesNames = allSeries.map((name) => {
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
      existingSeries = (
        <p className="crayons-field__description">
          Existing series:
          {seriesNames}
        </p>
      );
    }

    if (published) {
      publishedField = (
        <div className="crayons-field mb-6">
          <div className="crayons-field__label color-accent-danger">Danger Zone</div>
          <Button variant="danger" onClick={onSaveDraft}>Unpublish post</Button>
        </div>
      );
    }
    return (
      <Dropdown className={visible && `inline-block w-100 bottom-100`}>
        <h3>Post options</h3>
        <div className="crayons-field mb-6">
          <label htmlFor="canonicalUrl" className="crayons-field__label">
            Canonical URL
          </label>
          <p className="crayons-field__description">
            Change meta tag
            <code>canonical_url</code>
            if this post was first published elsewhere (like your own blog).
          </p>
          <input
            type="text"
            value={canonicalUrl}
            className="crayons-textfield"
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
          />
          {existingSeries}
        </div>
        {publishedField}
        <Button className="w-100" data-content="exit" onClick={onExit}>
          Done
        </Button>
      </Dropdown>
    );
  }
}

Options.propTypes = {
  onExit: PropTypes.func.isRequired,
  passedData: PropTypes.shape({
    published: PropTypes.bool.isRequired,
    allSeries: PropTypes.array.isRequired,
    canonicalUrl: PropTypes.string.isRequired,
    series: PropTypes.string.isRequired,
  }).isRequired,
  onSaveDraft: PropTypes.func.isRequired,
  onConfigChange: PropTypes.func.isRequired,
  visible: PropTypes.bool.isRequired,
};


Options.displayName = 'Options';
