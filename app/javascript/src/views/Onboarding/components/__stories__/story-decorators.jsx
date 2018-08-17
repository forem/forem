import { h } from 'preact';
import GlobalModalWrapper from './GlobalModalWrapper';

export const globalModalDecorator = story => (
  <GlobalModalWrapper>{story()}</GlobalModalWrapper>
);
