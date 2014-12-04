require 'spec_helper'

describe ActiveNode::Base do
  describe ".subclass" do
    it "should be ActiveNode::Base" do
      expect(ActiveNode::Base.subclass('Abc')).to be <= ActiveNode::Base
    end

    it "should have the right label" do
      expect(ActiveNode::Base.subclass('Abc').label).to eq('Abc')
    end

    it "should find object via subclass" do
      p = Person.create! name: 'Heinrich'
      expect(ActiveNode::Base.subclass('Person').find(p.id)[:name]).to eq(p.name)
    end
  end

  # it_behaves_like "ActiveModel"
end
