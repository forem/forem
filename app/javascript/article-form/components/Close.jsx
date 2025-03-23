import { h } from 'preact';
import { ButtonNew as Button } from '@crayons';
import CloseIcon from '@images/x.svg';

export const Close = ({ displayModal = () => {} }) => {
  return (
    <div className="crayons-article-form__close hidden-shell-innerhidden">
      <Button
        icon={CloseIcon}
        onClick={() => displayModal()}
        title="Close the editor"
        aria-label="Close the editor"
      />
    </div>
  );
};

Close.displayName = 'Close';
