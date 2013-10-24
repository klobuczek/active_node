class Client < ActiveNode::Base
  attribute :name, type: String

  has_many :users, direction: :incoming, class_name: 'NeoUser'

  validates :name, presence: true
end