import { h } from 'preact';
import PropTypes from 'prop-types';

export const EditorFormattingHelp = ({ openModal }) => (
  <div
    data-testid="format-help"
    className="crayons-article-form__help crayons-article-form__help--body"
  >
    <h4 className="mb-2 fs-l">Editor Basics</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
        Use{' '}
        <a href="#markdown" onClick={() => openModal('markdownShowing')}>
          Markdown
        </a>{' '}
        to write and format posts.
        <details className="fs-s my-1">
          <summary class="cursor-pointer">Commonly used syntax</summary>
          <table className="crayons-card crayons-card--secondary crayons-table crayons-table--compact w-100 mt-2 mb-4 lh-tight">
            <tbody>
              <tr>
                <td className="ff-monospace">
                  # Header
                  <br />
                  ...
                  <br />
                  ###### Header
                </td>
                <td>
                  H1 Header
                  <br />
                  ...
                  <br />
                  H6 Header
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">*italics* or _italics_</td>
                <td>
                  <em>italics</em>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">**bold**</td>
                <td>
                  <strong>bold</strong>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">[Link](https://...)</td>
                <td>
                  <a href="https://forem.com">Link</a>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  * item 1<br />* item 2
                </td>
                <td>
                  <ul class="list-disc ml-5">
                    <li>item 1</li>
                    <li>item 2</li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  1. item 1<br />
                  2. item 2
                </td>
                <td>
                  <ul class="list-decimal ml-5">
                    <li>item 1</li>
                    <li>item 2</li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">&gt; quoted text</td>
                <td>
                  <span className="pl-2 border-0 border-solid border-l-4 border-base-50">
                    quoted text
                  </span>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">`inline code`</td>
                <td>
                  <code>inline code</code>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  <span class="fs-xs">```</span>
                  <br />
                  code block
                  <br />
                  <span class="fs-xs">```</span>
                </td>
                <td>
                  <div class="highlight p-2 overflow-hidden">
                    <code>code block</code>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </details>
      </li>
      <li>
        You can use{' '}
        <a href="#liquid" onClick={() => openModal('liquidShowing')}>
          Liquid tags
        </a>{' '}
        to add rich content such as Tweets, YouTube videos, etc.
      </li>
      <li>
        In addition to images for the post's content, you can also drag and drop
        a cover image
      </li>
    </ul>
  </div>
);

EditorFormattingHelp.propTypes = {
  openModal: PropTypes.func.isRequired,
};
