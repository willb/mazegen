# mazerenderer.rb is licensed under the Apache Software License, version 2.0 
# and Copyright (c) 2010 William Benton (http://willbenton.com)

class Array
  def flatten_once
    self.inject([]) do |acc, val|
      val.is_a?(Array) ? acc + val : acc << val
    end
  end
end

class MazeRenderer
  def initialize(m, cellsize)
    @maze = m
    @cellsize = cellsize
  end
  
  def render_lines
    acc = []
    cols,rows = @maze.size
    (0...rows).each do |y|
      (0...cols).each do |x|
        corners = gen_corners(x,y)
        @maze.closed_sides(y*cols+x).each do |wall|
          case wall
            when :top then 
              acc << [corners[:ul], corners[:ur]]
            when :bottom then 
              acc << [corners[:bl], corners[:br]]
            when :left then 
              acc << [corners[:ul], corners[:bl]]
            when :right then
              acc << [corners[:ur], corners[:br]]
          end
        end
      end
    end
    
    acc
  end
  
  private
  def gen_corners(x,y)
    pairs = {:ul=>[x,y],:ur=>[x+1,y],:bl=>[x,y+1],:br=>[x+1,y+1]}.map {|key,val| [key,val.map{|p| p * @cellsize}]}
    Hash[*pairs.flatten_once]
  end
end
