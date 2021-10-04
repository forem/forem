import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

export const EditorFormattingHelp = ({ openModal }) => (
  <div
    data-testid="format-help"
    className="crayons-article-form__help crayons-article-form__help--body"
  >
    <h4 className="mb-2 fs-l">{i18next.t('editor.help.basics.heading')}</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
        {i18next.t('editor.help.basics.desc1')}
        <a href="#markdown" onClick={() => openModal('markdownShowing')}>
          {i18next.t('editor.help.basics.markdown')}
        </a>
        {i18next.t('editor.help.basics.desc2')}
        <details className="fs-s my-1">
          <summary class="cursor-pointer">
            {i18next.t('editor.help.basics.syntax')}
          </summary>
          <table className="crayons-card crayons-card--secondary crayons-table crayons-table--compact w-100 mt-2 mb-4 lh-tight">
            <tbody>
              <tr>
                <td className="ff-monospace">
                  # {i18next.t('editor.help.basics.header')}
                  <br />
                  {i18next.t('common.etc')}
                  <br />
                  ###### {i18next.t('editor.help.basics.header')}
                </td>
                <td>
                  {i18next.t('editor.help.basics.h1')}
                  <br />
                  {i18next.t('common.etc')}
                  <br />
                  {i18next.t('editor.help.basics.h6')}
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  {i18next.t('editor.help.basics.em_mono')}
                </td>
                <td>
                  <em>{i18next.t('editor.help.basics.em')}</em>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  {i18next.t('editor.help.basics.strong_mono')}
                </td>
                <td>
                  <strong>{i18next.t('editor.help.basics.strong')}</strong>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  [{i18next.t('editor.help.basics.link')}](https://...)
                </td>
                <td>
                  <a href="https://forem.com">
                    {i18next.t('editor.help.basics.link')}
                  </a>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  * {i18next.t('editor.help.basics.ul1')}
                  <br />* {i18next.t('editor.help.basics.ul2')}
                </td>
                <td>
                  <ul class="list-disc ml-5">
                    <li>{i18next.t('editor.help.basics.ul1')}</li>
                    <li>{i18next.t('editor.help.basics.ul2')}</li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  1. {i18next.t('editor.help.basics.ol1')}
                  <br />
                  2. {i18next.t('editor.help.basics.ol2')}
                </td>
                <td>
                  <ol class="list-decimal ml-5">
                    <li>{i18next.t('editor.help.basics.ol1')}</li>
                    <li>{i18next.t('editor.help.basics.ol2')}</li>
                  </ol>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  &gt; {i18next.t('editor.help.basics.quote')}
                </td>
                <td>
                  <span className="pl-2 border-0 border-solid border-l-4 border-base-50">
                    {i18next.t('editor.help.basics.quote')}
                  </span>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  {i18next.t('editor.help.basics.inline_code_mono')}
                </td>
                <td>
                  <code>{i18next.t('editor.help.basics.inline_code')}</code>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  <span class="fs-xs">```</span>
                  <br />
                  {i18next.t('editor.help.basics.code_block')}
                  <br />
                  <span class="fs-xs">```</span>
                </td>
                <td>
                  <div class="highlight p-2 overflow-hidden">
                    <code>{i18next.t('editor.help.basics.code_block')}</code>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </details>
      </li>
      <li>
        {i18next.t('editor.help.basics.desc3')}
        <a href="#liquid" onClick={() => openModal('liquidShowing')}>
          {i18next.t('editor.help.basics.liquid')}
        </a>
        {i18next.t('editor.help.basics.desc4')}
      </li>
      <li>{i18next.t('editor.help.basics.desc5')}</li>
    </ul>
  </div>
);

EditorFormattingHelp.propTypes = {
  toggleModal: PropTypes.func.isRequired,
};
