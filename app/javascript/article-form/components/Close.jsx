import { h } from 'preact';
import { Button } from '@crayons';

export const Close = ({ displayModal = () => {} }) => {
  const Icon = () => (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      className="crayons-icon"
      xmlns="http://www.w3.org/2000/svg"
      role="img"
      aria-labelledby="as1mn15llu5e032u2pgzlc6yhvss2myk"
    >
      <title id="as1mn15llu5e032u2pgzlc6yhvss2myk">Close the editor</title>
      <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
    </svg>
  );

  return (
    <div className="crayons-article-form__close">
      <Button
        variant="ghost"
        contentType="icon"
        icon={Icon}
        onClick={() => displayModal()}
      />
    </div>
  );
};

Close.displayName = 'Close';
