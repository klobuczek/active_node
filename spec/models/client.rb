class Client < ActiveNode::Base
  attribute :name, type: String

  has_many :users, direction: :incoming, class_name: 'NeoUser'
  has_one :address

  validates :name, presence: true
end