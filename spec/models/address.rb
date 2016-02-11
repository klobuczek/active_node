class Address < ActiveNode::Base
  attribute :city, type: String, default: "New York"
  has_one :person, direction: :incoming
  has_one :client, direction: :incoming
end