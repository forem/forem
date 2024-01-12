import { h } from 'preact';

export const TagInput = () => (
  <div
    data-testid="basic-tag-input-help"
    className="crayons-article-form__help crayons-article-form__help--tags"
  >
    <h4 className="mb-2 fs-l">Tagging Guidelines</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
        Tags help people find your post - think of them as the topics or
        categories that best describe your post.
      </li>
      <li>
        Add up to four comma-separated tags per post. Use existing tags whenever
        possible.
      </li>
      <li>
        Some tags have special posting guidelines - double check to make sure
        your post complies with them.
      </li>
    </ul>
  </div>
);
