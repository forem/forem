import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types/default-children-prop-types';

export const Modal = ({children, onToggleHelp, title}) => {
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
    <div className="crayons-modal">
      <div className="crayons-modal__box">
        <div className="crayons-modal__box__header">
          <h2>{title}</h2>
          <Button
            onClick={onToggleHelp}
            variant="ghost"
            contentType="icon"
            icon={Icon}
          />
        </div>
        <div
          className="crayons-modal__box__body"
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{ __html: children }}
        />
      </div>
      <div className="crayons-modal__overlay" />
    </div>
  );
};

Modal.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  onToggleHelp: PropTypes.func.isRequired,
  title: PropTypes.string.isRequired,
};

Modal.displayName = 'Modal';
