require 'yaml/store'
require 'psyphr'

# Create settings.yml file
STORE = YAML::Store.new "#{Rails.root}/config/settings.yml"

# Initialise the values
STORE.transaction do
  STORE[:arl_count] = 0
end

# Generate the first ARL
Psyphr.generate_arl
