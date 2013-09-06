require 'spec_helper'

describe ActiveNode::Validations do
  describe "#save" do
    it "should not save invalid object" do
      Client.new.save.should be_false
    end

    it "should save invalid object" do
      Client.new(name: 'abc7').save.should be_true
      Client.all.first.name.should == 'abc7'
    end
  end
end
