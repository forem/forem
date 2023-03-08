import { h } from 'preact';

export const ArticleFormTitle = () => (
  <div
    data-testid="title-help"
    className="crayons-article-form__help crayons-article-form__help--title"
  >
    <h4 className="mb-2 fs-l">Як написати чудовий заголовок</h4>
    <ul className="list-disc pl-6 color-base-70">
      <li>
		Подумайте про заголовок вашого допису як про дуже короткий (але переконливий!) опис.
        Як огляд самого допису в одному короткому реченні. 
      </li>
      <li>
		Використовуйте теґи там, де це доречно, щоб люди могли знайти вашу публікацію
        за допомогою пошуку.
      </li>
    </ul>
  </div>
);
