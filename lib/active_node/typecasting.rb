require "active_node/typecasting/time_typecaster"

module ActiveNode
  module Typecasting
    # @private
    EXTENDED_TYPECASTER_MAP = {
        Time => TimeTypecaster
    }.freeze

    def typecaster_for(type)
      EXTENDED_TYPECASTER_MAP[type].try(:new) or super
    end
  end
end
