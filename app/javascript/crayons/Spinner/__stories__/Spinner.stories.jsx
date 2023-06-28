import { h } from 'preact';
import { Spinner } from '../Spinner';

export default {
  component: Spinner,
  title: 'Components/Spinner',
};

export const Default = () => {
  return <Spinner />;
};

Default.storyName = 'default';
