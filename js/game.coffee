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

  astar = new Astar {grid: [10,10], start: [1,1], end: [5,5]}
  astar.search()

class Astar
  constructor: (options) ->
    {@grid, @start, @end} = options
    highlight @start, 'green'
    highlight @end, 'red'
    @open_list = []

  search: ->
    @open_list = [@start]
    for node in this._scored_nodes([1,1])
      node.
    console.log "grid = #{@grid}"
    console.log "h = #{this._heuristic(@start)}"
    console.log this._scored_nodes([1,1])

  _heuristic: (point) -> # Currently manhattan distance
    (@end[0] - point[0]) + (@end[1] - point[1])

  _candidate_nodes: (point) ->
    [
      [point[0], point[1]-1] # Above
      [point[0], point[1]+1] # Below
      [point[0]-1, point[1]] # Left
      [point[0]+1, point[1]] # Right
    ]

  _suitable_nodes: (point) ->
    grid = @grid
    this._candidate_nodes(point).filter (cpoint) ->
      cpoint[0] > 0 && cpoint[1] > 0 &&
      cpoint[0] <= grid[0] && cpoint[1] <= grid[1]

  _scored_nodes: (point) ->
    scored_nodes = []
    for node in this._suitable_nodes(point)
      scored_nodes.push {
        h: this._heuristic(point)
        # g: 
        point: node
        parent: point

      }

    scored_nodes.sort (a,b) ->
      if a.score > b.score then 1 else -1
