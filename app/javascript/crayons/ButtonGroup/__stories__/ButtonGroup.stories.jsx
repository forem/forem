import { h } from 'preact';
import {
  Button,
  SecondaryButton,
  OutlinedButton,
  DangerButton,
  ButtonGroup,
} from '@crayons';

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
      <Button>I&apos;m the primary</Button>
      <OutlinedButton>I&apos;m outlined</OutlinedButton>
      <DangerButton>Danger!</DangerButton>
      <SecondaryButton icon={Icon}>Hello!</SecondaryButton>
      <SecondaryButton icon={Icon} />
    </ButtonGroup>
  );
};
