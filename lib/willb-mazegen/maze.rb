# maze.rb is licensed under the Apache Software License, version 2.0 
# and Copyright (c) 2010 William Benton (http://willbenton.com)

# common infrastructure
module MazeBase
  def initialize(x,y)
    @cg = CellGraph.new(x,y)
    @startcell = 0
    @endcell = (@cg.x * @cg.y) - 1
  end
  
  attr_reader :cg
  
  def size 
    [@cg.x,@cg.y]
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
end

# Prim algorithm maze generator
class MazePrim
  include MazeBase
  
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

  private
  def reset
    @cg.reset_edges
    
    @maze_cells = (Set.new << 0)
    @walls = walls_for(0)
  end
end

# recursive-backtracking DFS maze generator
class MazeDFS
  include MazeBase

  def gen
    @first_cell = rand(cg.x * cg.y)
    reset
    gen_from(@first_cell)
  end
  
  private
  def reset
    @cg.reset_edges
    
    @maze_cells = SortedSet.new
    @neighbor_set = Hash.new {|h,cell| h[cell] =  @cg.neighbors(cell).reject {|x| @maze_cells.include?(x)}; h[cell]}
  end

  def gen_from(cell)
    @maze_cells << cell

    my_neighbor_set = @neighbor_set[cell]

    while not my_neighbor_set.empty?
      dest = my_neighbor_set.delete_at(rand(my_neighbor_set.size))
      @cg.add_edge(cell=>dest)
      gen_from(dest)
      my_neighbor_set.reject! {|x| @maze_cells.include?(x)}
    end
  end
end
