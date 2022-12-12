require "./spec_helper"

module Barista
  describe ColorIterator do
    it "cycles through colors" do
      iterator = ColorIterator.new
      colors = iterator.colors

      colors.concat(colors).each do |color|
        iterator.next.should eq(color)
      end
    end
  end
end
