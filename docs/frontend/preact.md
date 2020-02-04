---
title: Preact
---

# Preact

[Preact](https://preactjs.com/) is an alternative to React with the same modern
API.

Preact components are packaged using [Webpacker](/frontend/webpacker) and the
Preact code is located in `app/javascript`.

The components are mounted when needed, look for `javascript_pack_tag` in the
view pages inside `app/views`.

## PropTypes

Preact supports
[PropTypes](https://reactjs.org/docs/typechecking-with-proptypes.html). When
creating Preact components, please ensure that you have defined your PropTypes.

### Common PropTypes

PropTypes can become repetitive. In simple cases where a PropType is a string or
number, this duplication is expected. For commonly used entities in the DEV
project, common PropTypes exist. All common PropTypes are located in the
`/app/javascript/src/components/common-prop-types` folder. For example, the user
entity that is referenced in many parts of the DEV codebase.

```javascript
import PropTypes from 'prop-types';

export const userPropTypes = PropTypes.shape({
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  profile_image_url: PropTypes.string.isRequired,
  summary: PropTypes.string.isRequired,
});
```

#### Using Common PropTypes

Common PropTypes are imported just like any other
[JavaScript Module](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules).
For example, here are two scenarios where a component needs to use the
`tagPropTypes`.

Example 1: Using the `tagPropTypes` with `PropTypes.arrayOf` to construct the
PropTypes for the `tags` prop.

```jsx
import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../../../components/common-prop-types';

const SomeComponentUsingTags = ({ tags = [] }) => (
  <ul>
    {tags.map(tag => (
      <li key={tag.id}>{tag.name}</li>
    ))}
  </ul>
);

SomeComponentUsingTags.displayName = 'SomeComponentUsingTags';
SomeComponentUsingTags.propTypes = {
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
};
```

Example 2: Using the `tagPropTypes` to construct the PropTypes for the `tag`
prop.

```jsx
import { h } from 'preact';
import { tagPropTypes } from '../../../components/common-prop-types';

const SomeComponentUsingOneTag = ({ tag }) => <li key={tag.id}>{tag.name}</li>;

SomeComponentUsingOneTag.displayName = 'SomeComponentUsingTags';
SomeComponentUsingOneTag.propTypes = {
  tag: tagPropTypes.isRequired,
};
```
