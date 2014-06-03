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
  $('div.d').filter ->
    $this = $(this)
    $this.data('y') == point[0] && $this.data('x') == point[1]
  .css({'background':colour})

$(document).ready ->
  game = new Game {debug: true}
  first_level = new Map {name: 'first_level', size:{x: 10, y: 10}, terrain: [], base_tile: 0}
  game.load_map first_level

  astar = new Astar {grid: [10,10], start: [2,2], end: [9,9]}
  astar.search()


class Node
  constructor: (options) ->
    {@coords, @f, @g, @h, @parent} = options


class Astar
  constructor: (options) ->
    {@grid, @start, @end} = options
    highlight @start, 'limegreen'
    highlight @end, 'red'
    @open_list = []

  search: ->
    @open_list = [@start]
    # Add suitable nodes to open list
    start_node = new Node({coords: @start, g: 0})
    start_node.h = this._h(start_node)

    for node in this._suitable_nodes(start_node)
      highlight node.coords, 'darkgreen'

    highlight this._scored_nodes(start_node)[0].coords, 'blue'

  _f: (node) ->
    this._g(node) + this._h(node)
  _g: (node) ->
    node.parent.g + 1
  _h: (node) -> # Currently manhattan distance
    (@end[0] - node.coords[0]) + (@end[1] - node.coords[1])

  _candidate_nodes: (node) ->
    coords = node.coords
    [
      new Node({coords: [coords[0], coords[1]-1], parent: node}), # Above
      new Node({coords: [coords[0], coords[1]+1], parent: node}), # Below
      new Node({coords: [coords[0]-1, coords[1]], parent: node}), # Left
      new Node({coords: [coords[0]+1, coords[1]], parent: node}) # Right
    ]

  _suitable_nodes: (node) ->
    grid = @grid
    this._candidate_nodes(node).filter (cnode) ->
      # Remove those nodes which are outside the grid bounds
      cnode.coords[0] > 0 && cnode.coords[1] > 0 &&
      cnode.coords[0] <= grid[0] && cnode.coords[1] <= grid[1]

  _scored_nodes: (node) ->
    nodes = this._suitable_nodes(node)
    for node in nodes
      node.g = this._g(node)
      node.h = this._h(node)
      node.f = this._f(node)

    nodes.sort (a,b) ->
      if a.f > b.f then 1 else -1
