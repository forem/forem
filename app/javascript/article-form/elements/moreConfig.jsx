import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions'



// const ImageManagement = ({ onExit }) => (
export default class MoreConfig extends Component {
  constructor(props) {
    super(props);
    // this.state = {insertionImageUrl: null}
  }

  render() {
    const { onExit, passedData, onSaveDraft } = this.props;
    let publishedField = '';
    if (passedData.published) {
      publishedField =  <div>
                          <h4>Danger Zone</h4>
                          <button onClick={onSaveDraft}>Unpublish Post</button>
                        </div>

    }
    return   <div
                className="articleform__overlay"
              >
              <h3>Additional Config/Settings</h3>
              <button
                class="articleform__exitbutton"
                data-content="exit"
                onClick={onExit}
                >×</button>
              <div>
                <label>Canonical URL</label>
                <input type="text" value={passedData.canonicalUrl} name="canonicalUrl" onKeyUp={this.props.onConfigChange}/>
              </div>
              <small>Change meta tag<code>canonical_url</code> if this post was first published elsewhere (like your own blog)</small>
              {publishedField}
             </div>
  }
}

MoreConfig.propTypes = {
  onExit: PropTypes.func.isRequired,
};