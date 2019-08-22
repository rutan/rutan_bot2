ENV['REPP_ENV'] ||= 'development'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies'

require 'repp'
require_relative './handlers/power_slack'

# auto loader
LIB_PATH = File.expand_path('..', __FILE__)
$:.unshift LIB_PATH
ActiveSupport::Dependencies.autoload_paths << LIB_PATH
