import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Tabs } from '../Tabs';
import { Tab } from '../Tab';

describe('<Tabs />', () => {
  it('has no accessibility errors when using buttons', async () => {
    const { container } = render(
      <Tabs elements="buttons">
        <Tab current>One</Tab>
        <Tab>two</Tab>
      </Tabs>,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has no accessibility errors when using links', async () => {
    const { container } = render(
      <Tabs elements="links">
        <Tab current>One</Tab>
        <Tab>two</Tab>
      </Tabs>,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders default Tabs with buttons', () => {
    const { container } = render(
      <Tabs elements="buttons">
        <Tab current>One</Tab>
        <Tab>two</Tab>
      </Tabs>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders default Tabs with links', () => {
    const { container } = render(
      <Tabs elements="links">
        <Tab current>One</Tab>
        <Tab>two</Tab>
      </Tabs>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders stacked Tabs', () => {
    const { container } = render(
      <Tabs stacked>
        <Tab current>One</Tab>
        <Tab>two</Tab>
      </Tabs>,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders fitted Tabs', () => {
    const { container } = render(
      <Tabs fitted>
        <Tab current>One</Tab>
        <Tab>two</Tab>
      </Tabs>,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });
});
