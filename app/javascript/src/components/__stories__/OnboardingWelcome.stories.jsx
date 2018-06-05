import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import GlobalModalWrapper from './GlobalModalWrapper';
import OnboardingWelcome from '../OnboardingWelcome';

storiesOf('OnboardingWelcome', module)
  .addDecorator(storyFn => <GlobalModalWrapper>{storyFn()}</GlobalModalWrapper>)
  .add('Default', () => <OnboardingWelcome />);
