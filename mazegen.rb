#!/usr/bin/env ruby

# mazegen.rb is a simple program that generates simple mazes by finding a
# spanning tree of the cells in the maze.  (Perhaps someday it will be have
# more interesting functionality.)  The mazes mazegen generates are PDF files
# that are designed to mostly fill a letter-sized sheet of paper.  To run
# mazegen, you'll need the prawn library for PDF generation.

# mazegen.rb is licensed under the Apache Software License, version 2.0 
# and copyright (c) 2010 William Benton (http://willbenton.com)

require 'rubygems'
require 'set'
require 'prawn'

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
    Hash[*pairs.flatten(1)]
  end
end

DEFAULT_WIDTH = 67
DEFAULT_HEIGHT = 90
PAGE_WIDTH = 536
PAGE_HEIGHT = 720

width = DEFAULT_WIDTH
height = DEFAULT_HEIGHT
cellsize = PAGE_WIDTH / DEFAULT_WIDTH

page_count = 1

op = OptionParser.new do |opts|
  opts.banner = "Usage mazegen.rb [options] outfile.pdf"
  
  opts.on("-w", "--width COLS", "width of maze in cells (defaults to 67)") do |w| 
    width = w.to_i
    cellsize = PAGE_WIDTH / width
    height = PAGE_HEIGHT / cellsize
  end
  
  opts.on("-p", "--pagecount NUM", "number of mazes to put in the output document") do |p| 
    page_count = p.to_i
  end
  
end

begin
  op.parse!
rescue OptionParser::InvalidOption
  puts op
  exit
end

m = Maze.new(width, height)

Prawn::Document.generate(ARGV[0]) do
  while page_count > 0
    page_count -= 1
    
    m.gen
    
    MazeRenderer.new(m,cellsize).render_lines.each do |lstart,lend|
      stroke {line lstart, lend}
    end
    
    start_new_page if page_count > 0
  end
end