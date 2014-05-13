require "active_support/core_ext/string/conversions"
require "active_support/time"

module ActiveNode
  module Typecasting
    class TimeTypecaster
      def call(value)
        value.to_time if value.respond_to? :to_time
      end
    end
  end
end
