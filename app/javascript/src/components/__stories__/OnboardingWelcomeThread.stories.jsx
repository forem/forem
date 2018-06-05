import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import GlobalModalWrapper from './GlobalModalWrapper';
import OnboardingWelcomeThread from '../OnboardingWelcomeThread';

storiesOf('OnboardingWelcomeThread', module)
  .addDecorator(storyFn => <GlobalModalWrapper>{storyFn()}</GlobalModalWrapper>)
  .add('Default', () => <OnboardingWelcomeThread />);
