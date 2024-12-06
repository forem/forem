Behavioural changes in TerserJS are listed [here](https://github.com/terser/terser/blob/master/CHANGELOG.md).

## Unreleased
## 1.2.2 (2 April 2024)
- update TerserJS to [5.30.2]
- build an unminified version to make security reviews easier

## 1.2.1 (28 March 2024)
- update TerserJS to [5.30.0]

## 1.2.0 (22 January 2024)
- update TerserJS to [5.27.0]
- remove sourcemap patches
- `pure_new` option added
- EOL rubies are no longer tested
- update rubocop

## 1.1.20 (27 November 2023)
- update TerserJS to [5.24.0]
- fix mangle properties, thanks @khaitu!

## 1.1.19 (19 October 2023)
- update TerserJS to [5.22.0]
- enable passing terser options with Rails directly

## 1.1.18 (5 September 2023)
- update TerserJS to [5.19.4]

## 1.1.17 (14 July 2023)
- update TerserJS to [5.19.0]

## 1.1.16 (01 June 2023)
- update TerserJS to [5.17.7]

## 1.1.15 (09 May 2023)
- update TerserJS to [5.17.3]
- add lhs_constants (default is true)

## 1.1.14 (24 February 2023)
- update TerserJS to [5.16.5]
- update Rubocop

## 1.1.13 (03 December 2022)
- update TerserJS to [5.16.1]

## 1.1.12 (15 July 2022)
- update TerserJS to [5.14.2]

## 1.1.11 (28 June 2022)
- add keep_classnames and keep_numbers available in terser (default is false)

## 1.1.10 (13 June 2022)
- update TerserJS to [5.14.1]

## 1.1.9 (04 May 2022)
- update TerserJS to [5.13.1]

## 1.1.8 (25 November 2021)
- update TerserJS to [5.10.0]

## 1.1.7 (23 September 2021)
- update TerserJS to [5.9.0]

## 1.1.6 (15 September 2021)
- update TerserJS to [5.8.0]

## 1.1.5 (29 June 2021)
- update TerserJS to [5.7.1]

## 1.1.4 (27 June 2021)
- update TerserJS to [5.7.0]
- use railtie to register compressor on Rails initialization

## 1.1.3 (23 March 2021)
- update TerserJS to [5.6.1]

## 1.1.2 (03 March 2021)
- update TerserJS to [5.6.0]

## 1.1.1 (19 November 2020)
- update TerserJS to [5.5.0]
- (bugfix) error messages
- update rubocop to 1.3.1

## 1.1.0 (17 November 2020)
- update TerserJS to [5.4.0]

## 1.0.2 (13 October 2020)
- LICENSE.txt encoding fix
- update rubocop to 0.93.1

## 1.0.1 (02 August 2020)
- share the context in order to speedup sprockets compilation

## 1.0.0 (13 July 2020)
- add sprockets wrapper
- drop Ruby < 2.3.0 support
- drop ES5 mode
- drop IE8 mode
- drop unsupported runtimes (therubyracer, therubyrhino) because they don't support ECMA6
- update tests and new options
- update SourceMap to [0.6.1](https://github.com/mozilla/source-map/compare/0.5.7...0.6.1)
- update TerserJS to [4.8.0]
- switch from UglifyJS to TerserJS (https://github.com/terser/terser)
- fork from Uglifier (https://github.com/lautis/uglifier/releases/tag/v4.2.0)
