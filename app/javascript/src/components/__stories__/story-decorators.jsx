import { h } from 'preact';
import GlobalModalWrapper from './GlobalModalWrapper';

// eslint-disable-next-line import/prefer-default-export
export const globalModalDecorator = story => (
  <GlobalModalWrapper>{story()}</GlobalModalWrapper>
);
