import { h } from 'preact';
import PropTypes from 'prop-types';

export const EditorFormattingHelp = ({ openModal }) => (
  <div
    data-testid="format-help"
    className="crayons-article-form__help crayons-article-form__help--body"
  >
    <h4 className="mb-2 fs-l">Основи редактора</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
        Використовуйте <a href="https://kutok.io/site/gaid_z_vykorystannya_markdown-381i" target="_blank">розмітку Markdown</a> щоб красиво оформлювати дописи.
        <details className="fs-s my-1">
          <summary class="cursor-pointer">Найчастіші способи використання</summary>
          <table className="crayons-card crayons-card--secondary crayons-table crayons-table--compact w-100 mt-2 mb-4 lh-tight">
            <tbody>
              <tr>
                <td className="ff-monospace">
                  # Підзаголовок
                  <br />
                  ...
                  <br />
                  ###### Підзаголовок
                </td>
                <td>
                  H1 Підзаголовок
                  <br />
                  ...
                  <br />
                  H6 Підзаголовок
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">*курсив* or _курсив_</td>
                <td>
                  <em>курсив</em>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">**жирний**</td>
                <td>
                  <strong>жирний</strong>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">[Посилання](https://...)</td>
                <td>
                  <a href="https://forem.com">Посилання</a>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  * пункт 1<br />* пункт 2
                </td>
                <td>
                  <ul class="list-disc ml-5">
                    <li>пункт 1</li>
                    <li>пункт 2</li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  1. пункт 1<br />
                  2. пункт 2
                </td>
                <td>
                  <ul class="list-decimal ml-5">
                    <li>пункт 1</li>
                    <li>пункт 2</li>
                  </ul>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">&gt; цитата</td>
                <td>
                  <span className="pl-2 border-0 border-solid border-l-2 border-base-50">
                    цитата
                  </span>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">`код`</td>
                <td>
                  <code>код</code>
                </td>
              </tr>
              <tr>
                <td className="ff-monospace">
                  <span class="fs-xs">```</span>
                  <br />
                  блок коду
                  <br />
                  <span class="fs-xs">```</span>
                </td>
                <td>
                  <div class="highlight p-2 overflow-hidden">
                    <code>блок коду</code>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </details>
      </li>
      <li>
        Вбудовуйте різноманітний контент, наприклад, твіти, відео з YouTube тощо. Використовуйте повний 
        URL: <code>{'{% embed https://... %}.'}</code>{' '}
        <a href="#liquid" onClick={() => openModal('liquidShowing')}>
          Дивитися повний перелік підтримуваних сайтів
        </a>
        .
      </li>
      <li>
        Окрім зображень для вмісту допису, ви також можете перетягнути зображення обкладинки.<hr>
		<a href="https://kutok.io/site/gaid_z_vykorystannya_markdown-381i" target="_blank">Повний ґайд розмітки</a>
      </li>
    </ul>
	
      <h4 className="mb-2 fs-l">Як краще писати?</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
        У нас є <a href="https://kutok.io/editorial/pro_shcho_i_yak_my_pyshemo-3hdk" target="_blank">допис</a>, який докладно розповідає про що краще не писати. Будь ласка, ознайомтеся з ним.
	  </li>
	  </ul>
	
  </div>
);

EditorFormattingHelp.propTypes = {
  openModal: PropTypes.func.isRequired,
};
