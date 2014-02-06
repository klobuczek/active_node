require 'spec_helper'

describe ActiveNode::Validations do
  describe "#save" do
    it "should not save invalid object" do
      Client.new.save.should be_false
    end

    it "should save valid object" do
      Client.new(name: 'abc7').save.should be_true
      Client.all.first.name.should == 'abc7'
    end

    it "should validate uniqueness" do
      Person.create! name: 'abc'
      Person.new(name: 'abc').should_not be_valid
    end
  end
end
