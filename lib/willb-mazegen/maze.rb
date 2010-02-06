# maze.rb is licensed under the Apache Software License, version 2.0 
# and copyright (c) 2010 William Benton (http://willbenton.com)

class Maze
  def initialize(x,y)
    @cg = CellGraph.new(x,y)
  end
  
  attr_reader :cg
  
  def size 
    [@cg.x,@cg.y]
  end
  
  def gen
    reset
    while @walls.size > 0
      source,dest = @walls.delete_at(rand(@walls.size))
      unless @maze_cells.include? dest
        @maze_cells << dest
        @cg.add_edge(source=>dest)
        @walls = @walls + walls_for(dest)
      end
    end
  end
  
  def walls_for(cell)
    @cg.neighbors(cell).map {|nbc| [cell,nbc]} - @cg.edges_from(cell)
  end
  
  def closed_sides(cell)
    cx,cy = @cg.coords_for_cell(cell)
    positions = {:left=>[-1,0], :right=>[+1,0], :top=>[0,-1], :bottom=>[0,+1]}
    result = positions.inject([]) do |acc, pair| 
      dir = pair[0]
      dx,dy = pair[1]
      candidate_coords = [cx+dx,cy+dy]
      acc << dir if !(cg.in_graph(*candidate_coords)) || (!cg.edges_from(cell).map {|s,d| d}.include? @cg.cell_for_coords(*candidate_coords))
      acc
    end
    
    result -= [:top] if cell == @startcell
    result -= [:bottom] if cell == @endcell
    
    result
  end
  
  private
  def reset
    @cg.reset_edges
    
    @maze_cells = (Set.new << 0)
    @walls = walls_for(0)
    
    @startcell = 0
    @endcell = (@cg.x * @cg.y) - 1
  end
end

