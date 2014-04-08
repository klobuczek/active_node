require 'spec_helper'

describe ActiveNode::Persistence do
  describe "#save" do
    it "should save an object" do
      a=Address.create!
      Address.find(a.id).should == a
    end

    it "should save not conventionally named object" do
      NeoUser.new(name: 'Heinrich').save.should be_true
      NeoUser.all.map(&:name).should == ['Heinrich']
    end

    it "should save object with non attribute properties with a name of a relationship" do
      child = Person.create!
      person = Person.create! children: [child]
      person[:children] = "Bob"
      person.save
      person = Person.find person.id
      person[:children].should == "Bob"
      person.children.should == [child]
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

  describe "#destroyed?" do
    it "returns false if a record has not been destroyed" do
      person = Person.create!
      expect(person).to_not be_destroyed
    end

    it "returns true after a record has been destroyed" do
      person = Person.create!
      person.destroy

      expect(person).to be_destroyed
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

    it 'should find an object with id of a different model' do
      Client.find(Person.create!.id).class.should == Person
    end
  end

  describe "#attributes" do
    it "should include id" do
      Person.create!(name: 'abc').attributes['id'].should_not be_nil
    end
  end

  describe "#to_param" do
    it "should return a string version of the id" do
      person = Person.create!
      person.to_param.should == person.id.to_s
    end

    it "should return nil if the id is nil" do
      person = Person.new
      person.to_param.should be_nil
    end
  end

  describe "#persisted?" do
    it "returns true if an id is assigned and the record is not destroyed" do
      person = Person.new id: 123
      expect(person).to be_persisted
    end

    it "returns false if an id is assigned and the record is destroyed" do
      person = Person.create!
      person.destroy
      expect(person).to_not be_persisted
    end

    it "returns false if an id is not assigned" do
      person = Person.new
      expect(person).to_not be_persisted
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
