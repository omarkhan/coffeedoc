(function() {
  /*
  AST helper functions
  ====================
  
  Useful functions for dealing with the CoffeeScript parse tree.
  */  var coffeescript;
  coffeescript = require('coffee-script');
  exports.getNodes = function(script) {
    /*
        Generates the AST from coffeescript source code.  Adds a 'type' attribute
        to each node containing the name of the node's constructor, and returns
        the expressions array
        */    var root_node;
    root_node = coffeescript.nodes(script);
    root_node.traverseChildren(false, function(node) {
      return node.type = node.constructor.name;
    });
    return root_node.expressions;
  };
  exports.getFullName = function(variable) {
    /*
        Given a variable node, returns its full name
        */    var name, p;
    name = variable.base.value;
    if (variable.properties.length > 0) {
      name += '.' + ((function() {
        var _i, _len, _ref, _results;
        _ref = variable.properties;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          _results.push(p.name.value);
        }
        return _results;
      })()).join('.');
    }
    return name;
  };
}).call(this);
