# Validate entry size on extract
# NOTE: this initializer can be removed when upgrading to rubyzip >= 2.0
# see https://github.com/rubyzip/rubyzip/pull/403
# see https://github.com/rubyzip/rubyzip#size-validation
Zip.validate_entry_sizes = true
