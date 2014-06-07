class Game
  TILE_SIZE: 24

  constructor: (options) ->
    {@size, @debug} = options
    @viewport = $('#viewport')
    @map_renderer = new MapRenderer(this)

  load_map: (map) ->
    @map_renderer.load_map map

class Map
  constructor: (options) ->
    {@name, @size, @terrain, @base_tile} = options

class MapRenderer
  constructor: (game) ->
    @game = game
    @map_element = $('#map')

  load_map: (map) ->
    @map = map
    this._render()
    
  _render: ->
    @map_element.empty()
    this._render_base_tiles()
    this._render_debug_tiles() if @game.debug

  _render_base_tiles: ->
    base = $("<div class='base t t#{@map.base_tile}'>")
    base.css({width: "#{@map.size.x * @game.TILE_SIZE}px", height: "#{@map.size.y * @game.TILE_SIZE}px"})
    @map_element.append(base)

  _render_debug_tiles: ->
    debug_tiles = $("<div id='debug-tiles'>")
    
    for idx in [0..(@map.size.y * @map.size.x)-1]
      tile = $("<div class='d'>")
      tile.data({x:(idx %% @map.size.x + 1), y:(idx // @map.size.x + 1)})
      debug_tiles.append tile
    
    debug_tiles.css({width: "#{@map.size.x * @game.TILE_SIZE}px"})
    
    @map_element.append(debug_tiles)


highlight = (point, colour) ->
  # console.log point, colour
  $('div.d').filter ->
    $this = $(this)
    $this.data('x') == point[0] && $this.data('y') == point[1]
  .css({'background':colour})

highlight_list = (nodes, colour) ->
  for node in nodes
    highlight node.coords, colour

$(document).ready ->
  game = new Game {debug: true}
  first_level = new Map {name: 'first_level', size:{x: 20, y: 20}, terrain: [], base_tile: 0}
  game.load_map first_level

  astar = new Astar {grid: [20,20], start: [1,1], end: [15,12]}
  path = astar.search()
  node = path
  astar.refresh_display()
  highlight node.coords, 'white'
  while node = node.parent
    highlight node.coords, 'white'


class Node
  constructor: (options) ->
    {@coords, @g, @h, @parent} = options
  
  f: ->
    @g + @h


class Astar
  constructor: (options) ->
    {@grid, @start, @end} = options
    @open   = []
    @closed = []
    @impassable = [
      [2,1],
      [2,2],
      [2,3],
      [2,4],
      [2,5],
      [2,6],
      [2,7],
      [2,8],
      [2,9],
      [2,10],
      [2,11],

      [4,2],
      [4,3],
      [4,4],
      [4,5],
      [4,6],
      [4,7],
      [4,8],
      [4,9],
      [4,10],
      [4,11],
      [4,12],
      [4,13],

      [4,13],
      [5,13],
      [6,13],
      [7,13],
      [8,13],
      [9,13],
      [10,13],
      [11,13],
      [12,13],
      [13,13],
      [14,13],
      [15,13],
      [16,13],
      [17,13],
      [18,13],
      [19,13],
      [20,13],

      [5,5],
      [6,5],
      [7,5],
      [8,5],
      [9,5],

      [5,8],
      [7,8],
      [8,8],
      [9,8],
      [10,8],
    ].map (coords) ->
      new Node({coords: coords})
    

  refresh_display: ->
    highlight_list @closed, 'rgba(255,0,0,0.3)'
    highlight_list @open, 'rgba(0,255,0,0.3)'
    highlight @start, 'limegreen'
    highlight @end, 'red'
    highlight_list @impassable, 'yellow'

  search: ->
    # Add suitable nodes to open list
    start_node = new Node({coords: @start, g: 0})
    start_node.h = this._heuristic(start_node)
    
    @open.push start_node
    lowest_score = start_node
    # this._move_to_closed(lowest_score)

    while true
      for node in this._scored_nodes(lowest_score)
        if existing_node = this._node_open(node)
          # If it's already on the list, keep the cheapest one
          if node.f() <= existing_node.f()
            @open = @open.filter (onode) -> onode isnt existing_node
            @open.push node
        else
          @open.push node
      
      this._move_to_closed(lowest_score)
      this._sort_open_list()
      
      if @open.length <= 0 # Could not find a path, return closest
        @closed = @closed.sort ->
          if a.f() > b.f() then 1 else -1
        return @closed[0]
      
      lowest_score = @open[0]

      if this._coords_equal(new Node({coords: @end}), lowest_score)
        node = lowest_score
        return node


  _heuristic: (node) -> # Currently Manhattan distance
    (Math.abs(@end[0] - node.coords[0]) + Math.abs(@end[1] - node.coords[1])) * 10

  _move_to_closed: (node) ->
    that = this
    @open = @open.filter (onode) ->
      !that._coords_equal(onode, node)
    @closed.push node

  _candidate_nodes: (parent) ->
    coords = parent.coords
    [
      new Node({coords: [coords[0]-1, coords[1]-1], parent: parent, g: parent.g + 14}), # Above Left
      new Node({coords: [coords[0],   coords[1]-1], parent: parent, g: parent.g + 10}), # Above
      new Node({coords: [coords[0]+1, coords[1]-1], parent: parent, g: parent.g + 14}), # Above Right
      new Node({coords: [coords[0]+1, coords[1]],   parent: parent, g: parent.g + 10}), # Right
      new Node({coords: [coords[0]+1, coords[1]+1], parent: parent, g: parent.g + 14}), # Below Right
      new Node({coords: [coords[0],   coords[1]+1], parent: parent, g: parent.g + 10}), # Below
      new Node({coords: [coords[0]-1, coords[1]+1], parent: parent, g: parent.g + 14}), # Below Left
      new Node({coords: [coords[0]-1, coords[1]],   parent: parent, g: parent.g + 10}), # Left
    ]

  _suitable_nodes: (node) ->
    that = this
    this._candidate_nodes(node).filter (cnode) ->
      # Remove those nodes which are outside the grid bounds
      cnode.coords[0] > 0 && cnode.coords[1] > 0 &&
      cnode.coords[0] <= that.grid[0] && cnode.coords[1] <= that.grid[1] &&
      # Remove nodes that are closed
      !that._node_closed(cnode) &&
      # Remove impassable nodes
      !that._node_impassable(cnode)
      
  _scored_nodes: (node) ->
    nodes = this._suitable_nodes(node)

    for snode in nodes
      snode.h = this._heuristic(snode)

    nodes.sort (a,b) ->
      if a.f() > b.f() then 1 else -1

  _sort_open_list: ->
    @open = @open.sort (a,b) ->
      if a.f() > b.f() then 1 else -1

  _node_in_list: (node, list) ->
    for list_node in list
      if this._coords_equal(node, list_node)
        return list_node
    return false

  _node_open: (node) ->
    this._node_in_list(node, @open)
  _node_closed: (node) ->
    !!this._node_in_list(node, @closed)
  _node_impassable: (node) ->
    !!this._node_in_list(node, @impassable)



  _coords_equal: (node1, node2) ->
    (
      (node1.coords[0] == node2.coords[0]) &&
      (node1.coords[1] == node2.coords[1])
    )
