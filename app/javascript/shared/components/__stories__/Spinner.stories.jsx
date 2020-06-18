import { h } from 'preact';
import { Spinner } from '../Spinner';

export default {
  component: Spinner,
  title: '4_App Components/Shared/Spinner',
};

export const Default = () => {
  return <Spinner />;
};

Default.story = {
  name: 'default',
};
