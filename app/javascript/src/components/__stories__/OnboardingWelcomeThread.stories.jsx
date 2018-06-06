import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { globalModalDecorator } from '../__stories__/story-decorators';
import OnboardingWelcomeThread from '../OnboardingWelcomeThread';

storiesOf('OnboardingWelcomeThread', module)
  .addDecorator(globalModalDecorator)
  .add('Default', () => <OnboardingWelcomeThread />);
