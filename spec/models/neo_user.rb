class NeoUser < ActiveNode::Base
  attribute :name, type: String
  has_many :clients
  validates :name, presence: true

  def self.type
    'user'
  end
end