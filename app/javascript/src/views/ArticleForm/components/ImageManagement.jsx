import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions'



// const ImageManagement = ({ onExit }) => (
export default class ImageManagement extends Component {
  constructor(props) {
    super(props);
    this.state = {insertionImageUrl: null}
  }
  handleMainImageUpload = e => {
    e.preventDefault();
    const payload = {image: e.target.files, wrap_cloudinary: true,}
    generateMainImage(payload, this.props.onMainImageUrlChange, null)
    // this.props.onMainImageUrlChange(e.target.value)
  }

  handleInsertionImageUpload = e => {
    const payload = {image: e.target.files,}
    generateMainImage(payload, this.handleInertImageUploadSuccess, null)
  }

  handleInertImageUploadSuccess = response => {
    this.setState({
      insertionImageUrl: response.link,
    })
  }

  triggerMainImageRemoval = e => {
    e.preventDefault();
    this.props.onMainImageUrlChange({link: null})
  }
  render() {
    const { onExit, mainImageUrl } = this.props;
    const { insertionImageUrl } = this.state;
    // mainImageUrl
    let mainImageArea;
    if (mainImageUrl) {
      mainImageArea = <div>
                        <img src={mainImageUrl} />
                        <button onClick={this.triggerMainImageRemoval}>Remove Cover Image</button>
                      </div>
    } else {
      mainImageArea = <div>
                        <input type="file" onChange={this.handleMainImageUpload}/>
                      </div>
    }
    let inertionImageArea;
    if (insertionImageUrl) {
      inertionImageArea = <div>
                            <h3>Markdown Image:</h3>
                            <input type="text" value={`![](${insertionImageUrl})`} />
                            <h3>Direct URL:</h3>
                            <input type="text" value={insertionImageUrl} />
                          </div>
    } else {
      inertionImageArea = <div>
                            <input type="file" onChange={this.handleInsertionImageUpload} />
                          </div>
    }
    return   <div
                className="articleform__imagemanagement"
              >
              <button
                class="articleform__exitbutton"
                data-content="exit"
                onClick={onExit}
                >×</button>
                <h2>Cover Image</h2>
                {mainImageArea}
                <h2>Body Images</h2>
                {inertionImageArea}
              </div>

              }
};

ImageManagement.propTypes = {
  onExit: PropTypes.func.isRequired,
};

// export default ImageManagement;
