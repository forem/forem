import { h } from 'preact';
import { Spinner } from '../Spinner';

export default {
  component: Spinner,
  title: '3_Components/Spinner',
};

export const Default = () => {
  return <Spinner />;
};

Default.story = {
  name: 'default',
};
