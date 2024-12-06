## 9.0.0 (2021-10-25)

Changes:

  - bumped version of FB Graph API to v5.0

## 8.0.0 (2020-10-20)

Changes:

  - user profile picture link includes access token (#344, @anklos)

## 7.0.0 (2020-08-03)

Changes:

  - bumped version of FB Graph API to v4.0

## 6.0.0 (2020-01-27)

Changes:

  - bumped version of FB Graph API to v3.0

## 5.0.0 (2018-03-29)

Changes:

  - bumped version of FB Graph API to v2.10 (#297, @piotrjaworski)
  - use only CRuby 2.0+ on CI (#298, @simi)

## 4.0.0 (2016-07-26)

Changes:

  - drop support for Ruby < 1.9.3 (@mkdynamic)
  - switch to versioned FB APIs, currently using v2.6 (#245, @printercu, @mkdynamic)
  - remove deprecated :nickname field from README example (#223, @abelorian)
  - add Ruby 2.2 + 2.3.0 to CI (#225, @tricknotes, @mkdynamic, @anoraak)
  - update example app (@mkdynamic)

## 3.0.0 (2015-10-26)

Changes:

  - remove query string from redirect_uri on callback by default (#221, @gioblu)
  - signed request parsing extracted to `OmniAuth::Facebook::SignedRequest` class. (#183, @simi, @Vrael)
  - change default value of `info_fields` to `name,email` for the [graph-api-v2.4](https://developers.facebook.com/blog/post/2015/07/08/graph-api-v2.4/). ([#209](https://github.com/mkdynamic/omniauth-facebook/pull/209))

## 2.0.1 (2015-02-21)

Bugfixes:

  - allow versioning by not forcing absolute path for graph requests (#180, @frausto)
  - allow the image_size option to be set as a symbol. (#182, @jgrau)

## 2.0.0 (2014-08-07)

Changes:

  - remove support for canvas app flow (765ed9, @mkdynamic)

Bugfixes:

  - bump omniauth-oauth2 dependency which addresses CVE-2012-6134 (#162, @linedotstar)
  - rescue `NoAuthorizationCodeError` in callback_phase (a0036b, @tomoya55)
  - fix CSRF exception when using FB JS SDK and parsing signed request (765ed9, @mkdynamic)

## 1.6.0 (2014-01-13)

Features:

  - ability to specify `auth_type` per-request (#78, @sebastian-stylesaint)
  - image dimension can be set using `image_size` option (#91, @weilu)
  - update Facebook authorize URL to fix broken authorization (#103, @dlackty)
  - adds `info_fields` option (#109, @bloudermilk)
  - adds `locale` parameter (#133, @donbobka, @simi)
  - add automatically `appsecret_proof` (#140, @nlsrchtr, @simi)

Changes:

  - `NoAuthorizationCodeError` and `UnknownSignatureAlgorithmError` will now `fail!` (#117, @nchelluri)
  -  don't try to parse the signature if it's nil (#127, @oriolgual)

## 1.5.1 (2013-11-18)

Changes:

  - don't use `access_token` in URL [CVE-2013-4593](https://github.com/mkdynamic/omniauth-facebook/wiki/Access-token-vulnerability:-CVE-2013-4593) (@homakov, @mkdynamic, @simi)

## 1.5.0 (2013-11-13)

Changes:

  - remove `state` param to fix CSRF vulnerabilty [CVE-2013-4562](https://github.com/mkdynamic/omniauth-facebook/wiki/CSRF-vulnerability:-CVE-2013-4562) (@homakov, @mkdynamic, @simi)

## 1.4.1 (2012-07-07)

Changes:

  - update to omniauth-oauth2 1.1.0 for csrf protection (@mkdynamic)

## 1.4.0 (2012-06-24)

Features:

  - obey `skip_info?` config (@mkdynamic)
  - add support of the `:auth_type` option to `:authorize_options` (#58, @JHeidinga, @mkdynamic)
  - support `access_token` parameter as part of the callback request (#62, @steverandy)

## 1.3.0 (2012-05-05)

Features:

  - dynamic permissions in the auth params (#30, @famoseagle)
  - add support for facebook canvas (@mkdynamic)
  - add verified key to the info hash (#34, @ryansobol)
  - add option to use secure url for image in auth hash (@mkdynamic)
  - add option to specify image size (@mkdynamic)

Changes:

  - have `raw_info` return an empty hash if the Facebook response returns false (#44, @brianjlandau)
  - prevent oauth2 from interpreting Facebook's expires field as `expires_in`, when it's really `expires_at` (#39, @watsonbox)
  - remove deprecated `offline_access` permission (@mkdynamic)
  - tidy up the `callback_url` option (@mkdynamic)

## 1.2.0 (2012-01-06)

Features:

  - add `state` to authorization params (#19, @GermanDZ)

Changes:

  - lock to `rack ~> 1.3.6` (@mkdynamic)

## 1.1.0 (2011-12-10)

Features:

  - add `callback_url` option (#13, @gumayunov)
  - support for parsing code from signed request cookie (client-side flow) (@mkdynamic)

## 1.0.0 (2011-11-19)

Features:

  - allow passing of display via option (@mkdynamic)

Bugfixes:

  - fix `ten_mins_from_now` calculation (#7, @olegkovalenko)

## 1.0.0.rc2 (2011-11-11)

Features:

  - allow passing `display` parameter (@mkdynamic)
  - included default scope (@mkdynamic)

## 1.0.0.rc1 (2011-10-29)

  - first public gem release (@mkdynamic)
