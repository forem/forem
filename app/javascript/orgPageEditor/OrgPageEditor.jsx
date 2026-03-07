import { h } from 'preact';
import { EditorBody } from '../article-form/components/EditorBody';

const TEXTAREA_ID = 'org_page_markdown';
const PLACEHOLDER = `Use Markdown and Liquid tags to customize your org page.\n\nExample:\n{% org_team your-org-slug %}\n{% org_team your-org-slug role=admins limit=5 %}\n{% org_posts your-org-slug %}\n{% org_posts your-org-slug limit=5 sort=reactions min_reactions=10 since=30d %}`;

export const OrgPageEditor = ({ defaultValue, textAreaName }) => {
  return (
    <EditorBody
      defaultValue={defaultValue}
      onChange={() => {}}
      textAreaId={TEXTAREA_ID}
      textAreaName={textAreaName}
      placeholder={PLACEHOLDER}
      ariaLabel="Page content"
      className="crayons-textfield crayons-textfield--ghost ff-monospace fs-l"
      version="v2"
    />
  );
};

OrgPageEditor.displayName = 'OrgPageEditor';
