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
        depth: [nil, 11.43],
      }.each do |aspect, (canvas, frame)|
        d0.send(aspect).must_equal canvas
        d1.send(aspect).must_equal frame
      end
    end
  end
end
