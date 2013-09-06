module ActiveNode
  module Core
    extend ActiveSupport::Concern

    def initialize(attributes = nil)
      @association_cache = {}
      super attributes
    end
  end
end