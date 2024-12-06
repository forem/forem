## Version 2.0 upgrade notes

### Using ESM module by default

New version of JsRoutes doesn't try to guess your javascript environment module system because JS has generated a ton of legacy module systems in the past. 
[ESM+Webpacker](/Readme.md#webpacker) upgrade is recommended. 

However, if you don't want to follow that pass, specify `module_type` configuration option instead based on module system available in your JS environment.
Here are supported values:

* CJS
* UMD
* AMD
* ESM
* nil

[Explaination Article](https://dev.to/iggredible/what-the-heck-are-cjs-amd-umd-and-esm-ikm)

If you don't want to use any JS module system and make routes available via a **global variable**, specify `nil` as a `module_type` and use `namespace` option:

``` ruby
JsRoutes.setup do |config|
  config.module_type = nil
  config.namespace = "Routes"
end
```

### JSDoc comment

New version of js-routes generates function comment in the [JSDoc](https://jsdoc.app) format.
If you have any problems with that, you can disable it like this:


``` ruby
JsRoutes.setup do |config|
  config.documentation = false
end
```

### `required_params` renamed

In case you are using `required_params` property, it is now renamed and converted to a method:

``` javascript
// Old style
Routes.post_path.required_params  // => ['id']
// New style
Routes.post_path.requiredParams() // => ['id']
```

### ParameterMissing error rework

`ParameterMissing` is renamed to `ParametersMissing` error and now list all missing parameters instead of just first encountered in its message. Missing parameters are now available via `ParametersMissing#keys` property.

``` javascript
try {
  return Routes.inbox_path();
} catch(error) {
  if (error.name === 'ParametersMissing') {
    console.warn(`Missing route keys ${error.keys.join(', ')}. Ignoring.`);
    return "#";
  } else {
    throw error;
  }
}
```
