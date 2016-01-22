require 'pry'
require 'fileutils'
require 'dimension_drawer'
require 'redis'
require 'json'

class MiaArtwork
  attr_reader :id, :dimensionString, :dimensions

  def initialize(id, dimensionString)
    @id = id
    @dimensionString = dimensionString

    self.process_dimensions()
  end

  def process_dimensions
    @dimensions = dimensionString.split("\n").map {|d| Dimension.new(d)}
  end

  def save_dimension_files!(prefix='')
    dir = File.join(prefix, "svgs", @id.to_s)
    file = File.expand_path("../#{dir}", __FILE__)
    FileUtils::mkdir_p(dir)
    @dimensions.each do |dimension|
      IO.write("#{file}/#{dimension.entity.gsub(' ', '-')}.svg", dimension.project!)
    end
  end
end

class Dimension
  attr_reader :centimeters, :entity, :width, :height, :depth

  def initialize(string)
    cm = string.match(/\(([0-9\.]+\s?x\s?[0-9\.]+\s?(x\s?[0-9\.]+\s?)?cm)\)/)
    entity = string.strip.match(/\(([a-zA-Z ]+?)\)$/)
    @width, @height, @depth = cm && cm[1].split(/\s?x\s?|\s?cm/).map(&:to_f)

    @centimeters = cm && cm[1]
  end

  def drawer
    DimensionDrawer.new(@height, @width, @depth, 400, 320)
  end

  def project!
    self.drawer.cabinet_projection
  end
end

class RedisMiaArtwork < MiaArtwork
  def initialize(id)
    @id = id && id.to_i
    rawData = self.class.redis.hget("object:#{@id/1000}", id)
    data = JSON.parse(rawData)
    @dimensionString = data["dimension"]

    self.process_dimensions
  end

  def self.redis
    @@redis ||= Redis.new
  end

  def self.buckets
    r = RedisMiaArtwork.redis
    # this is a klunky way of getting all buckets `object:[0-125]`
    r.keys('object:[0-9]')
    .concat(r.keys('object:[0-9][0-9]'))
    .concat(r.keys('object:[0-9][0-9][0-9]'))
  end

  def self.all_ids
    @@all_ids ||= self.buckets.reduce([]) do |all, bucket|
      all.concat(self.redis.hgetall(bucket).keys)
    end
  end

  def self.project_all
    puts "OK…"
    self.all_ids.each do |id|
      printf id + ' '
      RedisMiaArtwork.new(id.to_i).save_dimension_files!
    end
  end
end
