import { h } from 'preact';

export const ArticleTips = () => (
  <div
    data-testid="article-publishing-tips"
    className="crayons-article-form__help crayons-article-form__help--tags"
  >
    <h4 className="mb-2 fs-l">Publishing Tips</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
        Ensure your post has a cover image set to make the most of the home feed
        and social media platforms.
      </li>
      <li>
        Share your post on social media platforms or with your co-workers or
        local communities.
      </li>
      <li>
        Ask people to leave questions for you in the comments. It's a great way
        to spark additional discussion describing personally why you wrote it or
        why people might find it helpful.
      </li>
    </ul>
  </div>
);
