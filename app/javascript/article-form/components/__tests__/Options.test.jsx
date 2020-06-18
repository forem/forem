import { h } from 'preact';
import { render } from '@testing-library/preact';
import { Options } from '../Options';

let passedData;

const getOptions = (passedData) => (
  <Options
    passedData={passedData}
    onConfigChange={null}
    onSaveDraft={null}
    moreConfigShowing={null}
    toggleMoreConfig={null}
  />
);

describe('<Options />', () => {

  beforeEach(() => {
    passedData = {
      "id": null,
      "title": "Test v2 Title",
      "tagList": "javascript, career, ",
      "description": "",
      "canonicalUrl": "",
      "series": "",
      "allSeries": [
        "Learn Something new a day"
      ],
      "bodyMarkdown": "![Alt Text](/i/wsq3lro2l66f87kqiqrf.jpeg)\nLet's write something here...",
      "published": false,
      "previewShowing": false,
      "previewResponse": "",
      "submitting": false,
      "editing": false,
      "mainImage": "/i/9pouqdqxcl4f6rwk1yfd.jpg",
      "organizations": [
        {
          "id": 4,
          "bg_color_hex": "",
          "name": "DEV",
          "text_color_hex": "",
          "profile_image_90": "/uploads/organization/profile_image/4/1689e7ae-6306-43cd-acba-8bde7ed80a17.JPG"
        }
      ],
      "organizationId": null,
      "errors": null,
      "edited": true,
      "updatedAt": null,
      "version": "v2",
      "helpFor": "article_body_markdown",
      "helpPosition": 421
    }
  });


  it('shows the danger zone once an article is published', ()=> {
    passedData.published = true;
    const { getByTestId } = render(getOptions(passedData));
    getByTestId('options__danger-zone');
  });
});
