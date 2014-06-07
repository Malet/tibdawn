// Generated by CoffeeScript 1.7.1
(function() {
  var Astar, Game, Map, MapRenderer, Node, highlight, highlight_list,
    __modulo = function(a, b) { return (a % b + +b) % b; };

  Game = (function() {
    Game.prototype.TILE_SIZE = 24;

    function Game(options) {
      this.size = options.size, this.debug = options.debug;
      this.viewport = $('#viewport');
      this.map_renderer = new MapRenderer(this);
    }

    Game.prototype.load_map = function(map) {
      return this.map_renderer.load_map(map);
    };

    return Game;

  })();

  Map = (function() {
    function Map(options) {
      this.name = options.name, this.size = options.size, this.terrain = options.terrain, this.base_tile = options.base_tile;
    }

    return Map;

  })();

  MapRenderer = (function() {
    function MapRenderer(game) {
      this.game = game;
      this.map_element = $('#map');
    }

    MapRenderer.prototype.load_map = function(map) {
      this.map = map;
      return this._render();
    };

    MapRenderer.prototype._render = function() {
      this.map_element.empty();
      this._render_base_tiles();
      if (this.game.debug) {
        return this._render_debug_tiles();
      }
    };

    MapRenderer.prototype._render_base_tiles = function() {
      var base;
      base = $("<div class='base t t" + this.map.base_tile + "'>");
      base.css({
        width: "" + (this.map.size.x * this.game.TILE_SIZE) + "px",
        height: "" + (this.map.size.y * this.game.TILE_SIZE) + "px"
      });
      return this.map_element.append(base);
    };

    MapRenderer.prototype._render_debug_tiles = function() {
      var debug_tiles, idx, tile, _i, _ref;
      debug_tiles = $("<div id='debug-tiles'>");
      for (idx = _i = 0, _ref = (this.map.size.y * this.map.size.x) - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; idx = 0 <= _ref ? ++_i : --_i) {
        tile = $("<div class='d'>");
        tile.data({
          x: __modulo(idx, this.map.size.x) + 1,
          y: Math.floor(idx / this.map.size.x) + 1
        });
        debug_tiles.append(tile);
      }
      debug_tiles.css({
        width: "" + (this.map.size.x * this.game.TILE_SIZE) + "px"
      });
      return this.map_element.append(debug_tiles);
    };

    return MapRenderer;

  })();

  highlight = function(point, colour) {
    return $('div.d').filter(function() {
      var $this;
      $this = $(this);
      return $this.data('x') === point[0] && $this.data('y') === point[1];
    }).css({
      'background': colour
    });
  };

  highlight_list = function(nodes, colour) {
    var node, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      _results.push(highlight(node.coords, colour));
    }
    return _results;
  };

  $(document).ready(function() {
    var astar, first_level, game, node, path, _results;
    game = new Game({
      debug: true
    });
    first_level = new Map({
      name: 'first_level',
      size: {
        x: 20,
        y: 20
      },
      terrain: [],
      base_tile: 0
    });
    game.load_map(first_level);
    astar = new Astar({
      grid: [20, 20],
      start: [1, 1],
      end: [15, 12]
    });
    path = astar.search();
    node = path;
    astar.refresh_display();
    highlight(node.coords, 'white');
    _results = [];
    while (node = node.parent) {
      _results.push(highlight(node.coords, 'white'));
    }
    return _results;
  });

  Node = (function() {
    function Node(options) {
      this.coords = options.coords, this.g = options.g, this.h = options.h, this.parent = options.parent;
    }

    Node.prototype.f = function() {
      return this.g + this.h;
    };

    return Node;

  })();

  Astar = (function() {
    function Astar(options) {
      this.grid = options.grid, this.start = options.start, this.end = options.end;
      this.open = [];
      this.closed = [];
      this.impassable = [[2, 1], [2, 2], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], [2, 8], [2, 9], [2, 10], [2, 11], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [4, 7], [4, 8], [4, 9], [4, 10], [4, 11], [4, 12], [4, 13], [4, 13], [5, 13], [6, 13], [7, 13], [8, 13], [9, 13], [10, 13], [11, 13], [12, 13], [13, 13], [14, 13], [15, 13], [16, 13], [17, 13], [18, 13], [19, 13], [20, 13], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5], [5, 8], [7, 8], [8, 8], [9, 8], [10, 8]].map(function(coords) {
        return new Node({
          coords: coords
        });
      });
    }

    Astar.prototype.refresh_display = function() {
      highlight_list(this.closed, 'rgba(255,0,0,0.3)');
      highlight_list(this.open, 'rgba(0,255,0,0.3)');
      highlight(this.start, 'limegreen');
      highlight(this.end, 'red');
      return highlight_list(this.impassable, 'yellow');
    };

    Astar.prototype.search = function() {
      var existing_node, lowest_score, node, start_node, _i, _len, _ref;
      start_node = new Node({
        coords: this.start,
        g: 0
      });
      start_node.h = this._heuristic(start_node);
      this.open.push(start_node);
      lowest_score = start_node;
      while (true) {
        _ref = this._scored_nodes(lowest_score);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (existing_node = this._node_open(node)) {
            if (node.f() <= existing_node.f()) {
              this.open = this.open.filter(function(onode) {
                return onode !== existing_node;
              });
              this.open.push(node);
            }
          } else {
            this.open.push(node);
          }
        }
        this._move_to_closed(lowest_score);
        this._sort_open_list();
        if (this.open.length <= 0) {
          this.closed = this.closed.sort(function() {
            if (a.f() > b.f()) {
              return 1;
            } else {
              return -1;
            }
          });
          return this.closed[0];
        }
        lowest_score = this.open[0];
        if (this._coords_equal(new Node({
          coords: this.end
        }), lowest_score)) {
          node = lowest_score;
          return node;
        }
      }
    };

    Astar.prototype._heuristic = function(node) {
      return (Math.abs(this.end[0] - node.coords[0]) + Math.abs(this.end[1] - node.coords[1])) * 10;
    };

    Astar.prototype._move_to_closed = function(node) {
      var that;
      that = this;
      this.open = this.open.filter(function(onode) {
        return !that._coords_equal(onode, node);
      });
      return this.closed.push(node);
    };

    Astar.prototype._candidate_nodes = function(parent) {
      var coords;
      coords = parent.coords;
      return [
        new Node({
          coords: [coords[0] - 1, coords[1] - 1],
          parent: parent,
          g: parent.g + 14
        }), new Node({
          coords: [coords[0], coords[1] - 1],
          parent: parent,
          g: parent.g + 10
        }), new Node({
          coords: [coords[0] + 1, coords[1] - 1],
          parent: parent,
          g: parent.g + 14
        }), new Node({
          coords: [coords[0] + 1, coords[1]],
          parent: parent,
          g: parent.g + 10
        }), new Node({
          coords: [coords[0] + 1, coords[1] + 1],
          parent: parent,
          g: parent.g + 14
        }), new Node({
          coords: [coords[0], coords[1] + 1],
          parent: parent,
          g: parent.g + 10
        }), new Node({
          coords: [coords[0] - 1, coords[1] + 1],
          parent: parent,
          g: parent.g + 14
        }), new Node({
          coords: [coords[0] - 1, coords[1]],
          parent: parent,
          g: parent.g + 10
        })
      ];
    };

    Astar.prototype._suitable_nodes = function(node) {
      var that;
      that = this;
      return this._candidate_nodes(node).filter(function(cnode) {
        return cnode.coords[0] > 0 && cnode.coords[1] > 0 && cnode.coords[0] <= that.grid[0] && cnode.coords[1] <= that.grid[1] && !that._node_closed(cnode) && !that._node_impassable(cnode);
      });
    };

    Astar.prototype._scored_nodes = function(node) {
      var nodes, snode, _i, _len;
      nodes = this._suitable_nodes(node);
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        snode = nodes[_i];
        snode.h = this._heuristic(snode);
      }
      return nodes.sort(function(a, b) {
        if (a.f() > b.f()) {
          return 1;
        } else {
          return -1;
        }
      });
    };

    Astar.prototype._sort_open_list = function() {
      return this.open = this.open.sort(function(a, b) {
        if (a.f() > b.f()) {
          return 1;
        } else {
          return -1;
        }
      });
    };

    Astar.prototype._node_in_list = function(node, list) {
      var list_node, _i, _len;
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        list_node = list[_i];
        if (this._coords_equal(node, list_node)) {
          return list_node;
        }
      }
      return false;
    };

    Astar.prototype._node_open = function(node) {
      return this._node_in_list(node, this.open);
    };

    Astar.prototype._node_closed = function(node) {
      return !!this._node_in_list(node, this.closed);
    };

    Astar.prototype._node_impassable = function(node) {
      return !!this._node_in_list(node, this.impassable);
    };

    Astar.prototype._coords_equal = function(node1, node2) {
      return (node1.coords[0] === node2.coords[0]) && (node1.coords[1] === node2.coords[1]);
    };

    return Astar;

  })();

}).call(this);
