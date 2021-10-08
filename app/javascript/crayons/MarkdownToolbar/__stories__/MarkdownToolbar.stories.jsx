import { h } from 'preact';
import { MarkdownToolbar } from '@crayons';

export default {
  title: 'App Components/MarkdownToolbar',
};

export const Default = () => {
  return (
    <div>
      <MarkdownToolbar textAreaId="text-area" />
      <textarea
        id="text-area"
        aria-label="Editor"
        className="crayons-textfield min-h-full border-0 radius-0"
      />
    </div>
  );
};

Default.story = {
  name: 'MarkdownToolbar',
};
