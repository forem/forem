import { h } from 'preact';
import { MarkdownToolbar } from '@crayons';

export default {
  title: 'App Components/Markdown Toolbar',
};

export const Default = () => {
  return (
    <div>
      <div
        style={{
          padding: 'var(--su-2) var(--content-padding-x)',
          background: 'var(--base-0)',
        }}
      >
        <MarkdownToolbar textAreaId="text-area" />
      </div>
      <textarea
        id="text-area"
        aria-label="Editor"
        className="crayons-textfield min-h-full border-0 radius-0"
      />
    </div>
  );
};

Default.storyName = 'MarkdownToolbar';
