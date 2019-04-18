import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { globalModalDecorator } from './story-decorators';
import OnboardingWelcomeThread from '../OnboardingWelcomeThread';

storiesOf('OnboardingWelcomeThread', module)
  .addDecorator(globalModalDecorator)
  .add('Default', () => <OnboardingWelcomeThread />);
