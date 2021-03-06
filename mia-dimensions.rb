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

    self.process_dimensions
  end

  def process_dimensions
    @dimensions ||= @dimensionString && @dimensionString.split("\n").map do |d|
      Dimension.new(d, @data)
    end
  end

  def save_dimension_files!(prefix='.')
    valid_dimensions = @dimensions && @dimensions.select(&:valid?)
    return unless valid_dimensions

    dir = File.join(prefix, "svgs", @id.to_s)
    absolute_dir = File.expand_path("../#{dir}", __FILE__)

    FileUtils::mkdir_p(dir)
    valid_dimensions.each.with_index do |dimension, i|
      name = "#{dimension.entity.gsub(' ', '-')}.svg"
      file = "#{absolute_dir}/#{name}"
      IO.write(file, dimension.project!)
      if i+1 == dimensions.length
        symlink = File.join(dir, 'dimensions.svg')
        FileUtils.ln_s(name, symlink, {force: true}) unless File.exist?(symlink)
      end
    end
  end

  def volume
    dimensions && dimensions[0].volume
  end
end

class Dimension
  attr_reader :centimeters, :entity, :width, :height, :depth

  def initialize(string, data=nil)
    cm = string.match(/\(([0-9\.]+\s?[x\|×]\s?[0-9\.]+\s?([x\|×]\s?[0-9\.]+\s?)?cm)\)/)
    entity = string.strip.match(/cm\)\s\(*([^\(]+)\)$/)
    @width, @height, @depth = cm && cm[1].split(/\s?[x\|×]\s?|\s?cm/).map(&:to_f)
    if @depth.nil?
      @depth = 0.1
      @imaginary_depth = true
    end

    @centimeters = cm && cm[1]
    @entity = entity ? entity[1].gsub(/[^a-zA-Z]+/, ' ').strip : 'dimensions'
    @data = data

    self.check_dimension_rotation
  end

  def drawer
    DimensionDrawer.new(@height, @width, @depth, 400, 320)
  end

  def project!
    self.drawer.cabinet_projection
  end

  def valid?
    @width && @height
  end

  def check_dimension_rotation
    if @width && @height && @data && @data['image_width']
      iw = @data['image_width'].to_f
      ih = @data['image_height'].to_f
      return unless iw && ih
      imageAspect = iw/ih
      dimensionAspect = @width/@height
      if imageAspect < 1 && dimensionAspect > 1 || imageAspect > 1 && dimensionAspect < 1
        @width, @height = @height, @width
      end
    end
  end

  def volume
    @width*@height * (@imaginary_depth ? 1 : @depth)
  end

  def volume2d
    @width*@height
  end

  def volume3d
    @width*@height * (@imaginary_depth ? 1 : @depth)
  end
end

class RedisMiaArtwork < MiaArtwork
  def initialize(id)
    @id = id && id.to_i
    rawData = self.class.redis.hget("object:#{@id/1000}", id)
    @data = JSON.parse(rawData)
    @dimensionString = @data["dimension"]

    self.process_dimensions
  rescue JSON::ParserError
    @dimensionString = ''
    @dimensions = nil
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

  def self.volume_elasticsearch
    self.all_ids.each do |id|
      art = RedisMiaArtwork.new(id.to_i)
      d = art.dimensions && art.dimensions[0]
      if d && d.width && d.height && d.volume
        [
          {update: {_type: "object_data", _id: id}},
          {doc: {volume: d.volume}}
        ].first(100).map do |json|
          puts JSON.dump(json)
        end
      end
    end
  end
end
