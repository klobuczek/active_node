require 'spec_helper'

describe ActiveNode::Base do
  describe ".subclass" do
    it "should be ActiveNode::Base" do
      ActiveNode::Base.subclass('Abc').should <= ActiveNode::Base
    end

    it "should have the right label" do
      ActiveNode::Base.subclass('Abc').label.should == 'Abc'
    end

    it "should find object via subclass" do
      p = Person.create! name: 'Heinrich'
      ActiveNode::Base.subclass('Person').find(p.id)[:name].should == p.name
    end
  end
end
