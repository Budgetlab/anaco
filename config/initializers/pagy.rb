# Pagy initializer file (v43.2)
# See https://ddnexus.github.io/pagy/docs/api/pagy

# Load the series helper support
require 'pagy/toolbox/helpers/support/series'

# Configure Pagy global options
Pagy.options[:limit] = 10
Pagy.options[:page_key] = 'p'
Pagy.options[:slots] = 7  # Number of page links to show (default: 7)

# Overflow behavior is now built into core - pages out of range return empty results
# Set raise_range_error: true in controller if you want to raise exceptions instead