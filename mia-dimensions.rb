require 'pry'
require 'dimension_drawer'

class MiaArtwork
  attr_reader :id, :dimensionString, :dimensions

  def initialize(id, dimensionString)
    @id = id
    @dimensionString = dimensionString

    self.process_dimensions()
  end

  def process_dimensions
    @dimensions = dimensionString.split("\n")
    @dimensions.map {|d| Dimension.new(d)}
  end
end

class Dimension
  attr_reader :centimeters, :entity, :width, :height, :depth

  def initialize(string)
    cm = string.match(/\(([0-9\.]+\s?x\s?[0-9\.]+\s?(x\s?[0-9\.]+\s?)?cm)\)/)
    entity = string.strip.match(/\(([a-zA-Z ]+?)\)$/)
    @width, @height, @depth = cm[1].split(/\s?x\s?|\s?cm/).map(&:to_f)

    @centimeters = cm && cm[1]
    @entity = entity && entity[1]
  end
end
