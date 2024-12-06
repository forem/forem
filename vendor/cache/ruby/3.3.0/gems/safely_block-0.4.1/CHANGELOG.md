## 0.4.1 (2024-09-04)

- Added support for Datadog

## 0.4.0 (2023-05-07)

- Added exception reporting from [Errbase](https://github.com/ankane/errbase)
- Dropped support for Ruby < 3

## 0.3.0 (2019-10-28)

- Made `safely` method private to behave like `Kernel` methods

## 0.2.2 (2019-08-06)

- Added `context` option

## 0.2.1 (2018-02-25)

- Tag exceptions reported with `report_exception`

## 0.2.0 (2017-02-21)

- Added `tag` option to `safely` method
- Switched to keyword arguments
- Fixed frozen string error
- Fixed tagging with custom error handler

## 0.1.1 (2016-05-14)

- Added `Safely.safely` to not pollute when included in gems
- Added `throttle` option

## 0.1.0 (2015-03-15)

- Added `tag` option and tag exception message by default
- Added `except` option
- Added `silence` option
