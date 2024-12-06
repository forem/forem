[![CI](https://github.com/SamSaffron/memory_profiler/workflows/CI/badge.svg)](https://github.com/SamSaffron/memory_profiler/actions?query=workflow%3ACI)
[![Gem Version](https://badge.fury.io/rb/memory_profiler.svg)](https://rubygems.org/gems/memory_profiler)

# MemoryProfiler

A memory profiler for Ruby

## Requirements

Ruby(MRI) Version 2.5.0 and above.

## Installation

Add this line to your application's Gemfile:

    gem 'memory_profiler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install memory_profiler

## Usage

There are two ways to use `memory_profiler`:
* command line
* convenience API

### Command Line

The easiest way to use memory_profiler is via the command line, which requires no modifications to your program. The basic usage is:
```
$ ruby-memory-profiler [options] <script.rb> [--] [script-options]
```
Where `script.rb` is the program you want to profile.

For a full list of options, execute the following command:
```
ruby-memory-profiler -h
```

### Convenience API

```ruby
require 'memory_profiler'
report = MemoryProfiler.report do
  # run your code here
end

report.pretty_print
```

Or, you can use the `.start`/`.stop` API as well:

```ruby
require 'memory_profiler'

MemoryProfiler.start

# run your code

report = MemoryProfiler.stop
report.pretty_print
```

**NOTE:**  `.start`/`.stop` can only be run once per report, and `.stop` will
be the only time you can retrieve the report using this API.

## Options

### `report`

The `report` method can take a few options:

* `top`: maximum number of entries to display in a report (default is 50)
* `allow_files`: include only certain files from tracing - can be given as a String, Regexp, or array of Strings
* `ignore_files`: exclude certain files from tracing - can be given as a String or Regexp
* `trace`: an array of classes for which you explicitly want to trace object allocations

Check out `Reporter#new` for more details.

```
pry> require 'memory_profiler'
pry> MemoryProfiler.report(allow_files: 'rubygems'){ require 'mime-types' }.pretty_print
Total allocated 82375
Total retained 22618

allocated memory by gem
-----------------------------------
rubygems x 305879

allocated memory by file
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb x 285433
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/basic_specification.rb x 18597
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems.rb x 2218
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/specification.rb x 1169
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/defaults.rb x 520
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_gem.rb x 80
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/version.rb x 80

. . .
```

### `pretty_print`

The `pretty_print` method can take a few options:

* `to_file`: a path to your log file - can be given a String
* `color_output`: a flag for whether to colorize output - can be given a Boolean
* `retained_strings`: how many retained strings to print - can be given an Integer
* `allocated_strings`: how many allocated strings to print - can be given a Integer
* `detailed_report`: should report include detailed information - can be given a Boolean
* `scale_bytes`: flag to convert byte units (e.g. 183200000 is reported as 183.2 MB, rounds with a precision of 2 decimal digits) - can be given a Boolean
* `normalize_paths`: flag to remove a gem's directory path from printed locations - can be given a Boolean
*Note: normalized path of a "location" from Ruby's stdlib will be prefixed with `ruby/lib/`. e.g.: `ruby/lib/set.rb`, `ruby/lib/pathname.rb`, etc.*


Check out `Results#pretty_print` for more details.

For example to report to file, use `pretty_print` method with `to_file` option and `path_to_your_log_file` string:
```
$ pry
pry> require 'memory_profiler'
pry> MemoryProfiler.report(allow_files: 'rubygems'){ require 'mime-types' }.pretty_print(to_file: 'path_to_your_log_file')

$ less my_report.txt
Total allocated 82375
Total retained 22618

allocated memory by gem
-----------------------------------
rubygems x 305879

. . .
```

## Example Session

You can easily use memory_profiler to profile require impact of a gem, for example:


```
pry> require 'memory_profiler'
pry> MemoryProfiler.report{ require 'mime-types'  }.pretty_print
Total allocated 82375
Total retained 22618

allocated memory by gem
-----------------------------------
mime-types-2.0 x 3668277
2.1.0-github/lib x 2035704
rubygems x 305879
other x 40

allocated memory by file
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb x 3391763
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb x 2021853
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb x 285433
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader.rb x 227033
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb x 48663
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/basic_specification.rb x 18597
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/parser.so x 8200
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/generator.so x 2463
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems.rb x 2218
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/specification.rb x 1169
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/defaults.rb x 520
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader_path.rb x 417
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/version.rb x 409
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types.rb x 361
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/generic_object.rb x 241
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/ext.rb x 200
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json.rb x 120
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_gem.rb x 80
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/version.rb x 80
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime-types.rb x 40
(pry) x 40

allocated memory by location
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 1985709
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:522 x 927503
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 827676
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:302 x 499525
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:625 x 281047
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:521 x 265920
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 265920
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:523 x 265920
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 222705
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader.rb:215 x 218105
[REDACTED]

allocated]objects by gem
-----------------------------------
mime-types-2.0 x 56564
2.1.0-github/lib x 22210
rubygems x 3600
other x 1

allocated objects by file
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb x 56237
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb x 21978
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb x 3388
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb x 291
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/basic_specification.rb x 169
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/parser.so x 124
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems.rb x 53
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/generator.so x 37
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/specification.rb x 26
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader.rb x 24
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/defaults.rb x 13
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/version.rb x 7
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types.rb x 6
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader_path.rb x 5
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/ext.rb x 5
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json.rb x 3
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/generic_object.rb x 3
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_gem.rb x 2
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/version.rb x 2
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime-types.rb x 1
(pry) x 1

allocated objects by location
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:522 x 21337
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 21095
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 9972
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:523 x 6648
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:521 x 6648
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 6648
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 3307
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:302 x 2955
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:625 x 1663
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:60 x 837
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:224 x 312
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb:62 x 287
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/parser.so:0 x 124
[REDACTED]

retained memory by gem
-----------------------------------
mime-types-2.0 x 1496813
2.1.0-github/lib x 519954
rubygems x 76195

retained memory by file
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb x 1447316
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb x 516679
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb x 75946
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb x 48583
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/generator.so x 2263
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/parser.so x 892
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader.rb x 577
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader_path.rb x 297
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/basic_specification.rb x 169
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/specification.rb x 80
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types.rb x 40
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/generic_object.rb x 40
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/ext.rb x 40
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/version.rb x 40

retained memory by location
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 516181
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:302 x 499525
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 414007
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:625 x 280878
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 132960
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:523 x 66480
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:135 x 58151
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:224 x 52728
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb:62 x 48503
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 17795
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/generator.so:0 x 2263
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/parser.so:0 x 892
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader.rb:239 x 577
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader_path.rb:15 x 257
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/basic_specification.rb:124 x 169
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:122 x 89
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:46 x 89
[REDUCTED]

retained objects by gem
-----------------------------------
mime-types-2.0 x 15211
2.1.0-github/lib x 7089
rubygems x 318

retained objects by file
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb x 14918
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb x 7045
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb x 315
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb x 289
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/generator.so x 32
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/parser.so x 9
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/specification.rb x 2
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader_path.rb x 2
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/loader.rb x 1
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types.rb x 1
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/version.rb x 1
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/generic_object.rb x 1
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/ext.rb x 1
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/basic_specification.rb x 1

retained objects by location
-----------------------------------
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 7035
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 4987
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 3324
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:302 x 2955
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:625 x 1662
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:523 x 1662
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:224 x 312
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 300
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/types/cache.rb:62 x 287
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/x86_64-linux/json/ext/generator.so:0 x 32
/home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:135 x 15
[REDUCTED]

Allocated String Report
-----------------------------------
"application" x 12050
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:522 x 4820
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:521 x 2410
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 2410
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 2410
"" x 6669
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:522 x 6648
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 11
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:266 x 4
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:71 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:72 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:69 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:0 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_gem.rb:39 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:70 x 1
"/" x 3342
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:523 x 3324
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 13
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:60 x 4
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:135 x 1
"encoding" x 3336
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 3324
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 10
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:135 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:60 x 1
"registered" x 3328
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 3324
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 4
"content-type" x 3327
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 3324
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 3
"references" x 2944
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 2940
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 4
"IANA" x 2824
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 1412
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:302 x 1412
[REDUCTED]

Retained String Report
-----------------------------------
"IANA" x 2824
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 1412
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:302 x 1412
"application" x 2410
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 1205
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 1205
"base64" x 1527
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/json/common.rb:155 x 1525
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:70 x 1
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 1
"audio" x 300
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 150
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 150
"video" x 188
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 94
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 94
"text" x 155
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:629 x 77
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/gems/2.1.0/gems/mime-types-2.0/lib/mime/type.rb:632 x 77
    /home/sam/.rbenv/versions/2.1.0-github/lib/ruby/2.1.0/rubygems/core_ext/kernel_require.rb:55 x 1
[REDUCTED]

```

The data is also available in the MemoryProfiler::Results object returned.

### Retained vs Allocated

The report breaks down 2 key concepts.

**Retained**: long lived memory use and object count retained due to the execution of the code block.

**Allocated**: All object allocation and memory allocation during code block.

As a general rule "retained" will always be smaller than or equal to allocated.

Memory profiler will tell you aggregate costs of the above, for example requiring the mime-types gem above results in approx 2MB of retained memory in 22K or so objects. The actual RSS cost will always be slightly higher as MRI heaps are not squashed to size and memory fragments. In future we may be able to calculate a rough long term GC cost of retained objects (for major GCs).

Memory profiler also performs some String analysis to help you find strings that would heavily benefit from #freeze. In the example above the string IANA is retained in memory 2824 times, this costs you a minimum of RVALUE_SIZE (40 on x64) * 2824.



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
