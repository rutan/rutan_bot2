require 'mobb/base'
require 'yaml'
require 'erb'
require 'ostruct'

module Extensions
  module MemoryCacheExtension
    class << self
      def registered(klass)
        klass.instance_eval do
          helpers Helpers
        end
      end
    end

    def memory_cache
      @memory_cache ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    module Helpers
      def memory_cache
        self.class.memory_cache
      end
    end
  end
end
