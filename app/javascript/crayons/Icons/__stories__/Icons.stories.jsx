import { h } from 'preact';
import { Icon } from '..';
import SampleIcon from '../../../../assets/images/twitter.svg';

export default {
  component: Icon,
  title: 'Components/Icons',
};

export const InheritColors = () => <Icon src={SampleIcon} />;
export const NativeColors = () => <Icon native src={SampleIcon} />;
