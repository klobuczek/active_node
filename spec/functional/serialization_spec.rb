describe ActiveNode::Persistence do
  describe '#to_json' do
    it 'should serialize' do
      expect(Person.create!(name: "abc").as_json["name"]).to eq 'abc'
    end
  end
end