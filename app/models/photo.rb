class Photo
  attr_accessor :id, :location
  attr_writer :contents

  def initialize(hash=nil)
    if !hash.nil?
      @id = hash[:_id].to_s if !hash[:_id].nil?
      @location = Point.new(hash[:metadata][:location]) if !hash[:metadata][:location].nil?
    end
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
    !@id.nil?
  end

  def save
    if !persisted?
      gps = EXIFR::JPEG.new(@contents).gps
      description = {}
      description[:content_type] = 'image/jpeg'
      description[:metadata] = {}
      @location = Point.new(:lng => gps.longitude, :lat => gps.latitude)
      description[:metadata][:location] = @location.to_hash

      if @contents
        @contents.rewind
        grid_file = Mongo::Grid::File.new(@contents.read, description)
        id = self.class.mongo_client.database.fs.insert_one(grid_file)
        @id = id.to_s
      end
    end
  end

  def self.all(skip=0, limit=nil)
    docs = mongo_client.database.fs.find({})
      .skip(skip)
    docs = docs.limit(limit) if !limit.nil?

    docs.map do |doc|
      Photo.new(doc)
    end
  end

  def self.find(id)
    doc = mongo_client.database.fs.find(:_id => BSON::ObjectId(id)).first
    return doc.nil? ? nil : Photo.new(doc)
  end

  def contents
    doc = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId(@id))
    if doc
      buffer = ""
      doc.chunks.reduce([]) do |x, chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def destroy
    self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId(@id)).delete_one
  end
end
