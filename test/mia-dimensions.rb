$LOAD_PATH << File.expand_path('../../', __FILE__)
require "maxitest/autorun"
require "mia-dimensions.rb"

lucretiaDimensions = "43 3/8 x 36 5/16 in. (110.17 x 92.28 cm) (canvas)\r\n59 1/4 x 52 5/16 x 4 1/2 in. (150.5 x 132.87 x 11.43 cm) (outer frame)"

describe "artwork dimensions" do
  let_all("art") { MiaArtwork.new(529, lucretiaDimensions) }
  let_all("d0") { Dimension.new(lucretiaDimensions.split("\n")[0]) }
  let_all("d1") { Dimension.new(lucretiaDimensions.split("\n")[1]) }

  describe MiaArtwork do
    it "should have an id" do
      art.id.must_equal 529
    end

    it "should have a dimension string" do
      art.dimensionString.must_equal lucretiaDimensions
    end

    it "has accessible dimensions" do
      art.dimensions.must_be_kind_of Array
    end

    it "saves dimension projection svg files" do
      art.save_dimension_files!('test')
      File.exist?("test/svgs/529/canvas.svg").must_equal true
      File.exist?("test/svgs/529/outer-frame.svg").must_equal true
    end

    it "symlinks one of the files to 'dimensions.svg'" do
      art.save_dimension_files!('test')
      File.exist?("test/svgs/529/dimensions.svg").must_equal true
    end

    it "doesn't save files for invalid JSON" do
      invalid = RedisMiaArtwork.new(6042)
      invalid.save_dimension_files!('test')
      File.exist?("test/svgs/6042").must_equal false
    end

    it "doesn't save files for invalid dimensions" do
      invalid = RedisMiaArtwork.new(6499)
      invalid.save_dimension_files!('test')
      File.exist?("test/svgs/6042").must_equal false
    end

    after { FileUtils.rm_rf("test/svgs") }
  end

  describe Dimension do
    it "has centimeter units measuring an 'entity'" do
      d0.centimeters.must_equal "110.17 x 92.28 cm"
    end

    it "measuring an 'entity'" do
      d0.entity.must_equal "canvas"
      d1.entity.must_equal "outer frame"
    end

    it "has width, height, depth" do
      {
        width: [110.17, 150.5],
        height: [92.28, 132.87],
        depth: [0.1, 11.43],
      }.each do |aspect, (canvas, frame)|
        d0.send(aspect).must_equal canvas
        d1.send(aspect).must_equal frame
      end
    end

    it "returns a dimension drawer" do
      d0.drawer.must_be_kind_of DimensionDrawer
    end

    it "and a cabinet projection" do
      d0.project!
    end

    it "handles dimensions without an entity" do
      d = Dimension.new("13 x 10 in. (33.02 x 25.4 cm)")
      d.width.must_equal 33.02
      d.height.must_equal 25.4
      d.depth.must_equal 0.1
      d.entity.must_equal 'dimensions'
    end
  end
end

describe RedisMiaArtwork do
  it "pulls its dimensions from redis" do
    jali = RedisMiaArtwork.new(13611)
    jali.dimensionString.must_equal "49 x 36 1/2 x 3 3/8 in. (124.5 x 92.7 x 8.6 cm)"
  end

  it "knows all the buckets" do
    buckets = RedisMiaArtwork.buckets
    buckets.must_be_kind_of Array
    buckets.size.must_be_within_epsilon 123, 10
  end

  it "knows all the artwork ids" do
    ids = RedisMiaArtwork.all_ids
    ids.must_be_kind_of Array
    ids.must_include "529"
    ids.size.must_be_within_epsilon 90000, 10000
  end
end
