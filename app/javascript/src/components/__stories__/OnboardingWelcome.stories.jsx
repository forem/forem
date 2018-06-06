import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { globalModalDecorator } from '../__stories__/story-decorators';
import OnboardingWelcome from '../OnboardingWelcome';

storiesOf('OnboardingWelcome', module)
  .addDecorator(globalModalDecorator)
  .add('Default', () => <OnboardingWelcome />);
