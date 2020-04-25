import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '../../crayons/Button';

export const Close = () => {
  const Icon = () => (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      className="crayons-icon"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
    </svg>
  );

  return (
    <div className="crayons-article-form__close">
      <Button variant="ghost" contentType="icon" url="/" tagName="a" icon={Icon} />
    </div>
  );
};

Close.displayName = 'Close';
