import { h } from 'preact';
import PropTypes from 'prop-types';

export const Cover = () => {
  return (
    <div className="crayons-article-form__cover">
      <button className="crayons-btn crayons-btn--secondary" type="button">Add a cover image</button>
    </div>
  );
};

Cover.displayName = 'Cover';
