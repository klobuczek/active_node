class Address < ActiveNode::Base
  attribute :city, type: String, default: "New York"
end