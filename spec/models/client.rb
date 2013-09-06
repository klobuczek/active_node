class Client < ActiveNode::Base
  attribute :name, type: String

  #has_many :phases
  has_many :users, type: :client, direction: :incoming, class_name: 'NeoUser'

  validates :name, presence: true
end