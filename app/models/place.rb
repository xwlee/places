class Place
  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize(hash)
    @id = hash[:_id].nil? ? hash[:id] : hash[:_id].to_s
    @formatted_address = hash[:formatted_address]
    @location = hash[:location]
    @address_components = hash[:address_components].map do |a|
      AddressComponent.new(a)
    end
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    mongo_client[:places]
  end

  def self.load_all(file)
    places = JSON.parse(file.read)
    collection.insert_many(places)
  end
end
