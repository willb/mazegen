# cellgraph.rb is licensed under the Apache Software License, version 2.0 
# and copyright (c) 2010 William Benton (http://willbenton.com)

# An undirected, unweighted graph of cells on a square grid; edges 
# indicate spaces, non-edges (between neighbors) indicate walls
class CellGraph
  def initialize(x,y)
    @x = x
    @y = y
    @node_coords = init_coords
    @node_edges = init_edges
    @node_neighbors = init_neighbors
  end
  
  attr_reader :x, :y
  
  def add_edges(edges)
    edges.each do |source,dest|
      @node_edges[source] << dest
      # recall that this is an undirected graph
      @node_edges[dest] << source
    end
  end

  alias add_edge add_edges

  def edges_from(node)
    @node_edges[node].map {|dest| [node, dest]}
  end

  def edges
    @node_edges.map do |source, dests|
      dests.map {|dest| [source, dest]}
    end.flatten(1)
  end
  
  def neighbors(node)
    @node_neighbors[node]
  end
  
  def coords_for_cell(node)
    @node_coords[node]
  end
  
  def cell_for_coords(x,y)
    @x * y + x
  end
  
  def in_graph(px,py)
    px >= 0 && py >= 0 && py < @y && px < @x
  end
  
  def reset_edges
    @node_edges = init_edges
  end
  
  private
  def init_coords
    Hash[*nodenums.zip(nodenums.map {|num| [num % @x, num / @x]}).flatten(1)]
  end

  def init_edges
    Hash.new do |hash,key|
      hash[key] = Set.new
    end
  end

  def init_neighbors
    Hash[*nodenums.zip(nodenums.map {|num| gen_neighbors(num)}).flatten(1)]
  end

  def nodenums
    (0...(@x * @y)).to_a
  end

  def gen_neighbors(node)
    coords = @node_coords[node]
    candidates = [[-1,0],[1,0],[0,-1],[0,1]].map {|dx,dy| [coords[0] + dx, coords[1] + dy]}
    candidates.select {|px,py| in_graph(px,py)}.map {|px,py| cell_for_coords(px,py)}
  end
end
