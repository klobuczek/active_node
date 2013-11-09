require 'spec_helper'

describe ActiveNode::Persistence do
  describe "#save" do
    it "should save not conventionally named object" do
      NeoUser.new(name: 'Heinrich').save.should be_true
      NeoUser.all.map(&:name).should == ['Heinrich']
    end

    it 'should destroy node' do
      user = NeoUser.create!(name: 'abc')
      NeoUser.all.count.should == 1
      user.destroy.should be_true
      NeoUser.all.count.should == 0
    end

    it 'should not destroy node with relationships' do
      person = Person.create! children: [Person.create!, Person.create!]
      person.destroy.should be_false
      Person.all.count.should == 3
    end

    it 'should destroy! node with relationships' do
      person = Person.create! children: [Person.create!, Person.create!]
      person.destroy!.should be_true
      Person.all.count.should == 2
    end

    it 'should record timestamp' do
      now = Time.now
      person = Person.create!
      person.created_at.should_not be_nil
      person = Person.find(person.id)
      person.created_at.should_not be_nil
      person.updated_at.should_not be_nil
      allow(Time).to receive(:now) { now + 1.second }
      person.name = 'abc'
      person.save
      (person.created_at < person.updated_at).should be_true
    end

    it 'should not record timestamp if not specified' do
      Client.create!(name: 'abc').respond_to?(:created_at).should be_false
    end
  end

  describe "#create!" do
    it "should persist attributes" do
      Person.create!(name: 'abc').name.should == 'abc'
    end

    it "should persist array properties" do
      person = Person.create!(multi: [1, 2, 3])
      Person.find(person.id).multi.should == [1, 2, 3]
    end

    it 'should not find an object with id of a different model' do
      Client.find(Person.create!.id).should be_nil
    end
  end

  describe "#attributes" do
    it "should include id" do
      Person.create!(name: 'abc').attributes['id'].should_not be_nil
    end
  end

  describe "#incoming" do
    it "can retrieve heterogenous models" do
      a = Address.create!
      p=Person.create!(name: 'abc', address: a)
      c=Client.create!(name: 'client', address: a)
      a.incoming(:address).should include(p, c)
    end
  end
end