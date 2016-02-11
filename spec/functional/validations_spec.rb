describe ActiveNode::Validations do
  describe "#save" do
    it "should not save invalid object" do
      expect(Client.new.save).to be_falsey
    end

    it "should save valid object" do
      expect(Client.new(name: 'abc7').save).to be_truthy
      expect(Client.all.first.name).to eq('abc7')
    end

    describe "with uniqueness constraint" do
      it "should validate uniqueness" do
        Person.create! name: 'abc'
        expect(Person.new(name: 'abc')).not_to be_valid
      end

      it "should still be valid after save" do
        person = Person.create! name: "abc"
        expect(person).to be_valid
      end
    end

    it "should validate presence on has_one" do
      expect(House.new).not_to be_valid
      house = House.create! address_id: Address.create!.id
      expect(House.find(house.id)).to be_valid
    end
  end

  describe "#create" do
    it "should not create invalid object" do
      expect(Client.create).not_to be_persisted
    end

    it "should create valid object" do
      expect(Client.create(name: 'abc7')).to be_persisted
      expect(Client.all.first.name).to eq('abc7')
    end

    it "should create an instance of the model class" do
      expect(Client.create(name: 'abc7')).to be_a(Client)
    end
  end
end
