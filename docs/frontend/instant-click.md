# InstantClick

Like the [InstantClick](http://instantclick.io/) tag line says, “InstantClick is
a JavaScript library that dramatically speeds up your website, making navigation
effectively instant in most cases.”.

The way it works is if a user hovers over a hyperlink, chances are their
intentions are to click on it. InstantClick will start prefetching the page
while a user is hovering over a hyperlink, so that by the time they do click on
it, it's instantaneous. On mobile devices, preloading starts on
[touchstart](https://developer.mozilla.org/en-US/docs/Web/API/Element/touchstart_event).

Aside from prefetching pages, InstantClick also allows you to customize what
happens when an InstantClick page changes.

```javascript
// Found in https://github.com/forem/forem/blob/main/app/javascript/packs/githubRepos.jsx#L11)
window.InstantClick.on('change', () => {
  loadElement();
});
```

You can also decide whether or not to reevaluate a script in an InstantClick
loaded page via the `data-no-instant` attribute.

```javascript
// Found in https://github.com/forem/forem/blob/main/app/assets/javascripts/utilities/buildCommentHTML.js.erb#L80
function actions(comment) {
  if (comment.newly_created) {
    return '<div class="actions" data-comment-id="'+comment.id+'" data-path="'+comment.url+'">\
        <span class="current-user-actions" style="display: '+ (comment.newly_created ? 'inline-block' : 'none') +';">\
          <a data-no-instant="" href="'+comment.url+'/delete_confirm" class="edit-butt" rel="nofollow">DELETE</a>\
          <a href="'+comment.url+'/edit" class="edit-butt" rel="nofollow">EDIT</a>\
        </span>\
      <a href="#" class="toggle-reply-form" rel="nofollow">REPLY</a>\
    </div>';
  } else {
...
```

For more information on this, see the
[Events and script re-evaluation in InstantClick](http://instantclick.io/scripts)
documentation.
