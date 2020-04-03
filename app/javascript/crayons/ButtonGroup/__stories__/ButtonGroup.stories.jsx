import { h } from 'preact';
import { Button, ButtonGroup } from '@crayons';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/ButtonGroup',
};

export const Default = () => {
  const Icon = () => (
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
  );

  return (
    <ButtonGroup>
      <Button>Hello World!</Button>
      <Button icon={Icon} />
    </ButtonGroup>
  );
};
