class House < ActiveNode::Base
  has_one :address

  validates :address, presence: true
end