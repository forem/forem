# Change Log

## [v1.0.0](https://github.com/zaru/webpush/tree/v1.0.0) (2019-08-15)

A stable version 1.0.0 has been released.

Thanks @mohamedhafez, @mplatov and @MedetaiAkaru for everything!

[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.8...v1.0.0)

**Merged pull requests:**

- switch to aes128gcm encoding [\#84](https://github.com/zaru/webpush/pull/84) ([mohamedhafez](https://github.com/mohamedhafez))
- Fixed fcm spec [\#77](https://github.com/zaru/webpush/pull/77) ([zaru](https://github.com/zaru))
- add fcm endpoints [\#76](https://github.com/zaru/webpush/pull/76) ([MedetaiAkaru](https://github.com/MedetaiAkaru))
- Add Rubocop and fix [\#74](https://github.com/zaru/webpush/pull/74) ([zaru](https://github.com/zaru))
- Fix TravisCI bundler version [\#73](https://github.com/zaru/webpush/pull/73) ([zaru](https://github.com/zaru))

## [v0.3.8](https://github.com/zaru/webpush/tree/v0.3.8) (2019-04-16)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.7...v0.3.8)

**Merged pull requests:**

- Fix authorization header [\#72](https://github.com/zaru/webpush/pull/72) ([xronos-i-am](https://github.com/xronos-i-am))

## [v0.3.7](https://github.com/zaru/webpush/tree/v0.3.7) (2019-03-06)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.6...v0.3.7)

**Merged pull requests:**

- Add PEM support to import / export keys [\#65](https://github.com/zaru/webpush/pull/65) ([collimarco](https://github.com/collimarco))

## [v0.3.6](https://github.com/zaru/webpush/tree/v0.3.6) (2019-01-09)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.5...v0.3.6)

**Merged pull requests:**

- Added a error class to arguments of raise\_error [\#62](https://github.com/zaru/webpush/pull/62) ([zaru](https://github.com/zaru))
- Fix TravisCI bundler version [\#61](https://github.com/zaru/webpush/pull/61) ([zaru](https://github.com/zaru))
- Raise Webpush::Unauthorized on HTTP 403 [\#59](https://github.com/zaru/webpush/pull/59) ([collimarco](https://github.com/collimarco))

## [v0.3.5](https://github.com/zaru/webpush/tree/v0.3.5) (2019-01-02)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.4...v0.3.5)

**Merged pull requests:**

- Fix \#55 and \#51: raise the proper error based on the HTTP status code [\#58](https://github.com/zaru/webpush/pull/58) ([collimarco](https://github.com/collimarco))
- Add urgency option [\#57](https://github.com/zaru/webpush/pull/57) ([collimarco](https://github.com/collimarco))
- Add Rake task to generate VAPID keys [\#54](https://github.com/zaru/webpush/pull/54) ([stevenharman](https://github.com/stevenharman))

## [v0.3.4](https://github.com/zaru/webpush/tree/v0.3.4) (2018-05-25)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.3...v0.3.4)

**Merged pull requests:**

- add http timeout options [\#50](https://github.com/zaru/webpush/pull/50) ([aishek](https://github.com/aishek))

## [v0.3.3](https://github.com/zaru/webpush/tree/v0.3.3) (2017-11-06)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.2...v0.3.3)

**Merged pull requests:**

- Add typ to JWT header fields [\#46](https://github.com/zaru/webpush/pull/46) ([ykzts](https://github.com/ykzts))
- Specify the version of JWT strictly [\#45](https://github.com/zaru/webpush/pull/45) ([ykzts](https://github.com/ykzts))

## [v0.3.2](https://github.com/zaru/webpush/tree/v0.3.2) (2017-07-01)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.1...v0.3.2)

**Merged pull requests:**

- feat: improve response error codes [\#39](https://github.com/zaru/webpush/pull/39) ([glennr](https://github.com/glennr))
- Update README.md [\#38](https://github.com/zaru/webpush/pull/38) ([kitaindia](https://github.com/kitaindia))
- Fix code example: Add close bracket [\#37](https://github.com/zaru/webpush/pull/37) ([kuranari](https://github.com/kuranari))
- fix code in README [\#36](https://github.com/zaru/webpush/pull/36) ([kuranari](https://github.com/kuranari))
- Minor fix in README: Close code blocks [\#32](https://github.com/zaru/webpush/pull/32) ([nicolas-fricke](https://github.com/nicolas-fricke))
- Copy edits for README clarifying GCM requirements [\#30](https://github.com/zaru/webpush/pull/30) ([rossta](https://github.com/rossta))
- Adding VAPID documentation [\#28](https://github.com/zaru/webpush/pull/28) ([rossta](https://github.com/rossta))

## [v0.3.1](https://github.com/zaru/webpush/tree/v0.3.1) (2016-10-24)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.3.0...v0.3.1)

**Merged pull requests:**

- Bug fix invalid base64 [\#29](https://github.com/zaru/webpush/pull/29) ([rossta](https://github.com/rossta))
- Clarify VAPID usage further in README [\#27](https://github.com/zaru/webpush/pull/27) ([rossta](https://github.com/rossta))

## [v0.3.0](https://github.com/zaru/webpush/tree/v0.3.0) (2016-10-14)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.2.5...v0.3.0)

**Merged pull requests:**

- Implement VAPID authorization [\#26](https://github.com/zaru/webpush/pull/26) ([rossta](https://github.com/rossta))

## [v0.2.5](https://github.com/zaru/webpush/tree/v0.2.5) (2016-09-14)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.2.4...v0.2.5)

**Merged pull requests:**

- api key only needed for old google apis [\#24](https://github.com/zaru/webpush/pull/24) ([mohamedhafez](https://github.com/mohamedhafez))

## [v0.2.4](https://github.com/zaru/webpush/tree/v0.2.4) (2016-08-29)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.2.3...v0.2.4)

**Merged pull requests:**

- VERIFY\_PEER by default - no need for a cert\_store option [\#20](https://github.com/zaru/webpush/pull/20) ([mohamedhafez](https://github.com/mohamedhafez))

## [v0.2.3](https://github.com/zaru/webpush/tree/v0.2.3) (2016-06-19)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.2.2...v0.2.3)

**Merged pull requests:**

- detect and handle response errors [\#18](https://github.com/zaru/webpush/pull/18) ([mohamedhafez](https://github.com/mohamedhafez))

## [v0.2.2](https://github.com/zaru/webpush/tree/v0.2.2) (2016-06-13)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.2.1...v0.2.2)

**Merged pull requests:**

- Don't include API key for firefox or other browsers [\#16](https://github.com/zaru/webpush/pull/16) ([mohamedhafez](https://github.com/mohamedhafez))
- Option to specify a cert store [\#15](https://github.com/zaru/webpush/pull/15) ([mohamedhafez](https://github.com/mohamedhafez))
- show ttl option in README [\#14](https://github.com/zaru/webpush/pull/14) ([mohamedhafez](https://github.com/mohamedhafez))

## [v0.2.1](https://github.com/zaru/webpush/tree/v0.2.1) (2016-05-23)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.2.0...v0.2.1)

**Merged pull requests:**

- Make the response more detailed. [\#10](https://github.com/zaru/webpush/pull/10) ([kevinjom](https://github.com/kevinjom))

## [v0.2.0](https://github.com/zaru/webpush/tree/v0.2.0) (2016-05-16)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.6...v0.2.0)

**Merged pull requests:**

- Make message payload optional [\#8](https://github.com/zaru/webpush/pull/8) ([rossta](https://github.com/rossta))
- Add specs [\#7](https://github.com/zaru/webpush/pull/7) ([rossta](https://github.com/rossta))

## [v0.1.6](https://github.com/zaru/webpush/tree/v0.1.6) (2016-05-12)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.5...v0.1.6)

**Merged pull requests:**

- Add rake binstub [\#6](https://github.com/zaru/webpush/pull/6) ([rossta](https://github.com/rossta))
- Add syntax highlighting to README snippets [\#5](https://github.com/zaru/webpush/pull/5) ([rossta](https://github.com/rossta))
- Extract encryption module [\#4](https://github.com/zaru/webpush/pull/4) ([rossta](https://github.com/rossta))
- Add some happy case specs [\#3](https://github.com/zaru/webpush/pull/3) ([waheedel](https://github.com/waheedel))

## [v0.1.5](https://github.com/zaru/webpush/tree/v0.1.5) (2016-04-29)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.4...v0.1.5)

**Merged pull requests:**

- add Ttl header parameter [\#1](https://github.com/zaru/webpush/pull/1) ([shouta-dev](https://github.com/shouta-dev))

## [v0.1.4](https://github.com/zaru/webpush/tree/v0.1.4) (2016-04-27)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.3...v0.1.4)

## [v0.1.3](https://github.com/zaru/webpush/tree/v0.1.3) (2016-04-13)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.2...v0.1.3)

## [v0.1.2](https://github.com/zaru/webpush/tree/v0.1.2) (2016-04-12)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.1...v0.1.2)

## [v0.1.1](https://github.com/zaru/webpush/tree/v0.1.1) (2016-03-31)
[Full Changelog](https://github.com/zaru/webpush/compare/v0.1.0...v0.1.1)

## [v0.1.0](https://github.com/zaru/webpush/tree/v0.1.0) (2016-03-31)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*