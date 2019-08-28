import { h } from 'preact';
import PropTypes from 'prop-types';

const MainImage = ({ mainImage, onEdit }) => (
  <div className="articleform__mainimage" onClick={onEdit}>
    <img src={mainImage} />
  </div>
);

MainImage.propTypes = {
  mainImage: PropTypes.string.isRequired,
};

export default MainImage;
