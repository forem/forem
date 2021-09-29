import { h } from 'preact';
import { MarkdownToolbar } from '@crayons';

export default {
  title: 'App Components/MarkdownToolbar',
};

export const Default = () => {
  return (
    <div>
      <MarkdownToolbar textAreaId="text-area" />
      <textarea id="text-area" />
    </div>
  );
};

Default.story = {
  name: 'MarkdownToolbar',
};
