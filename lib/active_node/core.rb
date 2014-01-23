module ActiveNode
  module Core
    extend ActiveSupport::Concern

    def initialize(attributes = nil, split_by=:respond_to_writer?)
      @association_cache = {}
      super attributes, split_by
    end
  end
end