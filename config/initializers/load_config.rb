require 'yaml'
require 'erb'

APP_CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/config.yml")).result)[Rails.env].symbolize_keys

