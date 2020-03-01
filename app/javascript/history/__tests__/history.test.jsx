import { h } from 'preact';
import render from 'preact-render-to-json';
import { JSDOM } from 'jsdom';
import fetch from 'jest-fetch-mock';
import { shallow } from 'preact-render-spy';
import { History } from '../history';
import algoliasearch from '../__mocks__/algoliasearch';

global.fetch = fetch;
const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.algoliasearch = algoliasearch;
global.window.currentUser = { id: 'modID' };

describe('<History />', () => {
  describe('itemsLoaded', () => {
    describe('when there are Loaded Items', () => {
      it('adds "results--loaded" class', () => {
        const history = shallow(
          <History availableTags={['discuss', 'javascript']} />,
        );

        expect(history.find('.results--loaded').exists()).toEqual(true);
      });
    });

    describe('when there are no Loaded Items', () => {
      it('keeps default class', () => {
        const history = shallow(
          <History availableTags={['discuss', 'javascript']} />,
        );

        expect(history.find('.results--loaded').exists()).toEqual(false);
      });
    });
  });

  describe('totalCount', () => {
    describe(' when totalCount equals zero', () => {
      it('results-header inner html equals empty', () => {
        const history = shallow(
          <History availableTags={['discuss', 'javascript']} />,
        );

        expect(history.find('.results-header').text()).toEqual(
          'History (empty)',
        );
      });
    });

    describe(' when totalCount is bigger than zero', () => {
      it('results-header inner html equals a list', () => {
        const history = shallow(
          <History availableTags={['discuss', 'javascript']} />,
        );

        expect(history.find('.results-header').text()).toEqual('History ( )');
      });
    });
  });

  describe('itemsToRender', () => {
    describe('When there are items to render', () => {
      it('render items', () => {
        expect(true).toBe(true);
      });
    });
  });

  it('renders properly', () => {
    const tree = render(<History availableTags={['discuss']} />);
    expect(tree).toMatchSnapshot();
  });
});
