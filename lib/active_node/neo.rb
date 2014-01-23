module ActiveNode
  class Neo
    def self.db
      @db ||= Neography::Rest.new
    end
  end
end