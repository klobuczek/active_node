describe ActiveNode::QueryMethods do
  describe "#order" do
    it "should order" do
      p1=Person.create!(name: 'abc')
      p2=Person.create!(name: 'def')
      expect(Person.order(:name)).to eq([p1, p2])
      expect(Person.order(name: :desc)).to eq([p2, p1])
      expect(Person.order('name asc').reverse_order).to eq([p2, p1])
    end
  end

  describe "#limit" do
    it "should limt" do
      p1=Person.create!(name: 'abc')
      p2=Person.create!(name: 'def')
      expect(Person.limit(1)).to eq([p1])
    end
  end

  describe "#count" do
    it "should respect block passed to count" do
      Person.create!(name: 'abc')
      expect(Person.count).to eq(1)
      expect(Person.count{|p| p.name == 'abc'}).to eq(1)
      expect(Person.count{|p| p.name != 'abc'}).to eq(0)
    end
  end
end
