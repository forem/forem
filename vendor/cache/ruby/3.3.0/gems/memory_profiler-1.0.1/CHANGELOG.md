# Changelog

## 1.0.1 - 23-10-2022

- Adapts tests to Ruby 3.0 / 3.1
- Lazy report evaluation
- Tested under Truffle Ruby

## 1.0.0 - 02-12-2020

- Added new CLI `ruby-memory-profiler` which can be used to profile scripts @fatkodima
- Reduced memory usage when generating reports
- Some optimizations for Ruby 2.7
- Remove EOL Rubies: 2.3 and 2.4 are no longer supported (use an earlier version of the gem if needed)

## 0.9.14 - 28-06-2019

- Pass 'normalize_path: true' to pretty_print to have locations stripped
- Improve number formatting

## 0.9.13 - 22-03-2019

- remove support explicitly for all EOL rubies, 2.1 and 2.2
- frozen string literal comment @RST-J
- scale_bytes option @RST-J

## 0.9.12
- Correct bug under-reporting memory for large string allocation @sam

## 0.9.11
- Reduce memory needed for string allocation tracing @dgynn
- Use yield rather than block.call to reduce an allocation @dgynn
- Ensure string allocation locations sort consistently @dgynn

## 0.9.10
- Add better detection for stdlib "gems"

## 0.9.9
- Add options for pretty printer to customize report

## 0.9.8
- Add optional start/stop sematics to memory profiler api @nicklamuro @dgynn

## 0.9.7
- Improved class name detection for proxy objects, BasicObject objects, and
 other edge cases @inossidabile @Hamdiakoguz @dgynn

## 0.9.6
- FIX: pretty_print was failing under some conditions @vincentwoo
- FIX: if #class is somehow nil don't crash @vincentwoo

## 0.9.5
- Improved stability and performance @dgynn

## 0.9.4
- FIX: remove incorrect RVALUE offset on 2.2  @dgynn
- FEATURE: add total memory usage @dgynn

## 0.9.3
- Add class reporting

## 0.9.2
- Fix incorrect syntax in rescue clause

## 0.9.0
- This is quite stable, upping version to reflect
- Fixed bug where it would crash when location was nil for some reason

## 0.0.4
- Added compatibility with released version of Ruby 2.1.0
- Cleanup to use latest APIs available in 2.1.0

## 0.0.3
- Added string analysis
