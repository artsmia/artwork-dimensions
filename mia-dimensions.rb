require 'pry'
require 'fileutils'
require 'dimension_drawer'

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
    @width, @height, @depth = cm[1].split(/\s?x\s?|\s?cm/).map(&:to_f)
    @depth = 0 if @depth.nil?

    @centimeters = cm && cm[1]
    @entity = entity && entity[1]
  end

  def drawer
    DimensionDrawer.new(@width, @height, @depth, 400, 320)
  end

  def project!
    self.drawer.cabinet_projection
  end
end
