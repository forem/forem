import { h, render as preactRender } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import fetch from 'jest-fetch-mock';
import Tags from '../../../shared/components/tags';

global.fetch = fetch;

const sampleResponse = JSON.stringify({
  result: [
    {
      name: 'git',
      hotness_score: 0,
      supported: true,
      short_summary: null,
    },
  ],
});

describe('<Tags />', () => {
  beforeEach(() => {
    const doc = new JSDOM('<!doctype html><html><body></body></html>');
    global.document = doc;
    global.window = doc.defaultView;
    fetch.mockResponse(sampleResponse);
  });

  it('renders properly', () => {
    const tree = render(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('shows tags as you search', () => {
    const context = shallow(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
    );
    const component = context.component();

    return component
      .handleInput({ target: { value: 'gi', selectionStart: 2 } })
      .then(() => {
        expect(context.state()).toMatchSnapshot();
      });
  });

  it('skips the click handler if className is articleform__tagsoptionrulesbutton', () => {
    // eslint-disable-next-line no-underscore-dangle
    const component = preactRender(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
      document.body,
      document.body.firstElementChild,
    )._component;

    component.handleTagClick({
      target: { className: 'articleform__tagsoptionrulesbutton' },
    });
    expect(component.state).toMatchSnapshot();
    expect(component.state.searchResults).toEqual([]);
  });

  it('selects tag when you click on it', () => {
    // eslint-disable-next-line no-underscore-dangle
    const component = preactRender(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
      document.body,
      document.body.firstElementChild,
    )._component;

    component.handleTagClick({
      target: {},
      currentTarget: { dataset: { content: 'git' } },
    });
    expect(component.state).toMatchSnapshot();
  });

  it('replaces tag when editing', () => {
    // eslint-disable-next-line no-underscore-dangle
    const component = preactRender(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
      document.body,
      document.body.firstElementChild,
    )._component;

    const input = document.getElementById('tag-input');
    input.value = 'java,javascript,linux';
    input.selectionStart = 2;

    component.handleTagClick({
      target: {},
      currentTarget: { dataset: { content: 'git' } },
    });
    expect(component.state).toMatchSnapshot();
  });

  it('shows tags when editing', () => {
    // eslint-disable-next-line no-underscore-dangle
    const component = preactRender(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
      document.body,
      document.body.firstElementChild,
    )._component;

    return component
      .handleInput({
        target: { value: 'gi, javascript, linux', selectionStart: 2 },
      })
      .then(() => {
        expect(component.state).toMatchSnapshot();
      });
  });

  it('only allows 4 tags', () => {
    const component = shallow(
      <Tags
        defaultValue=""
        onInput={jest.fn()}
        classPrefix="articleform"
        maxTags={4}
      />,
    );

    component.simulate('input', {
      target: { value: 'java, javascript, linux, productivity' },
    });

    component.simulate('keydown', { keyCode: 188, preventDefault: jest.fn() });
    expect(component.state()).toMatchSnapshot();
  });
});
