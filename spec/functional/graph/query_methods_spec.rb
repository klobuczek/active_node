require 'spec_helper'

describe ActiveNode::QueryMethods do
  describe "#order" do
    it "should order" do
      p1=Person.create!(name: 'abc')
      p2=Person.create!(name: 'def')
      Person.order(:name).should == [p1, p2]
      Person.order(name: :desc).should == [p2, p1]
      Person.order('name asc').reverse_order.should == [p2, p1]
    end
  end

  describe "#limit" do
    it "should limt" do
      p1=Person.create!(name: 'abc')
      p2=Person.create!(name: 'def')
      Person.limit(1).should == [p1]
    end
  end
end
