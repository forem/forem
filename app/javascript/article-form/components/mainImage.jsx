import { h } from 'preact';
import PropTypes from 'prop-types';

const MainImage = ({ mainImage, onEdit }) => (
  <div
    className="articleform__mainimage"
    role="presentation"
    onClick={onEdit}
    onKeyUp={(e) => {
      if (e.key === 'Enter') {
        onEdit(e);
      }
    }}
  >
    <img src={mainImage} alt="" />
  </div>
);

MainImage.defaultProps = {
  onEdit: () => {},
};

MainImage.propTypes = {
  mainImage: PropTypes.string.isRequired,
  onEdit: PropTypes.func,
};

export default MainImage;
