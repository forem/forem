import { h } from 'preact';
import { CoverImagePropTypes } from '../../src/components/common-prop-types';

const CoverImage = ({ className, imageSrc, imageAlt }) => (
  <div className={className}>
    <img src={imageSrc} alt={imageAlt} />
  </div>
);

CoverImage.propTypes = CoverImagePropTypes;

export default CoverImage;
