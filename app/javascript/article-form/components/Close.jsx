import { h } from 'preact';
import { ButtonNew as Button } from '@crayons';
import CloseIcon from '@images/x.svg';

export const Close = ({ displayModal = () => {} }) => {
  return (
    <div className="crayons-article-form__close">
      <Button
        icon={CloseIcon}
        onClick={() => displayModal()}
        title="Завершити редагування"
        aria-label="Завершити редагування"
      />
    </div>
  );
};

Close.displayName = 'Close';
