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
  first_level = new Map {name: 'first_level', size:{x: 10, y: 12}, terrain: [], base_tile: 0}
  game.load_map first_level

  astar = new Astar {grid: [10,12], start: [1,1], end: [10,7]}
  astar.search()


class Node
  constructor: (options) ->
    {@coords, @g, @h, @parent} = options
  
  f: ->
    @g + @h


class Astar
  constructor: (options) ->
    {@grid, @start, @end} = options
    highlight @start, 'limegreen'
    highlight @end, 'red'
    @open   = []
    @closed = []
    @impassable = [
      new Node({coords: [2,1]}),
      new Node({coords: [2,2]}),
      new Node({coords: [2,3]}),
      new Node({coords: [2,4]}),
      new Node({coords: [2,5]}),
      new Node({coords: [2,6]}),
      new Node({coords: [2,7]}),
      new Node({coords: [2,8]}),

      new Node({coords: [5,2]}),
      new Node({coords: [5,3]}),
      new Node({coords: [5,4]}),
      new Node({coords: [5,5]}),
      new Node({coords: [5,6]}),
      new Node({coords: [5,7]}),
      new Node({coords: [5,8]}),
      new Node({coords: [5,9]}),
      new Node({coords: [5,10]}),

      new Node({coords: [6,6]}),
      new Node({coords: [7,6]}),
      new Node({coords: [8,6]}),
      new Node({coords: [9,6]}),
    ]

  refresh_display: ->
    console.log "===="
    for c in @closed
      console.log "closed: ", c.coords, c.f(), c.g, c.h

    for o in @open
      console.log "open: ", o.coords, o.f(), o.g, o.h
    highlight_list @closed, 'darkred'
    highlight_list @open, 'green'
    highlight_list @impassable, 'yellow'

  search: ->
    # Add suitable nodes to open list
    start_node = new Node({coords: @start, g: 0})
    start_node.h = this._heuristic(start_node)
    
    @open.push start_node
    lowest_score = start_node
    # this._move_to_closed(lowest_score)

    finished = false
    while !finished && @open.length > 0
      this._move_to_closed(lowest_score)
      
      for node in this._scored_nodes(lowest_score)
        this.open.push node unless this._node_open(node)
      
      this.refresh_display()

      lowest_score = this._scored_nodes(lowest_score)[0]

      if this._coords_equal(new Node({coords: @end}), lowest_score)
        node = lowest_score
        while typeof node != 'undefined'
          console.log node.coords
          highlight node.coords, 'aqua'
          node = node.parent
        finished = true


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

  _node_in_list: (node, list) ->
    for list_node in list
      if this._coords_equal(node, list_node)
        return true
    return false

  _node_open: (node) ->
    this._node_in_list(node, @open)
  _node_closed: (node) ->
    this._node_in_list(node, @closed)
  _node_impassable: (node) ->
    this._node_in_list(node, @impassable)



  _coords_equal: (node1, node2) ->
    (
      (node1.coords[0] == node2.coords[0]) &&
      (node1.coords[1] == node2.coords[1])
    )
