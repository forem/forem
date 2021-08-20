---
title: Preact
---

# Preact

[Preact](https://preactjs.com/) is an alternative to React with the same modern
API.

Preact components are packaged using [Webpacker](/frontend/webpacker) and the
Preact code is located in `app/javascript`.

Preact components get loaded via webpacker's helper function
`javascript_packs_with_chunks_tag`.

## PropTypes

Preact supports
[PropTypes](https://reactjs.org/docs/typechecking-with-proptypes.html). When
creating Preact components, please ensure that you have defined your PropTypes.

### Common PropTypes

Using PropTypes can be repetitive. Some duplication is normal, like when a
PropType is a string or a number. But for commonly-used PropTypes, like the user
entity, you can use the provided common PropTypes, located in the
`/app/javascript/common-prop-types`, as shown below.

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

In the example below, our component `SomeComponentUsingTags` has a `tags` prop,
which is an array of the tag entity. PropTypes have a built-in method called
`arrayOf` that allows you to define a prop as an array of something. In our
case, this is the tag entity, so we can use the `tagPropTypes` PropType.

```jsx
import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../../../components/common-prop-types';

const SomeComponentUsingTags = ({ tags = [] }) => (
  <ul>
    {tags.map((tag) => (
      <li key={tag.id}>{tag.name}</li>
    ))}
  </ul>
);

SomeComponentUsingTags.displayName = 'SomeComponentUsingTags';
SomeComponentUsingTags.propTypes = {
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
};
```

In the following example, the `SomeComponentUsingOneTag` component has a `tag`
prop representing a single tag. In this case, we can just the `tagPropTypes` on
their own to represent the shape of the `tag` prop.

```jsx
import { h } from 'preact';
import { tagPropTypes } from '../../../components/common-prop-types';

const SomeComponentUsingOneTag = ({ tag }) => <li key={tag.id}>{tag.name}</li>;

SomeComponentUsingOneTag.displayName = 'SomeComponentUsingTags';
SomeComponentUsingOneTag.propTypes = {
  tag: tagPropTypes.isRequired,
};
```
