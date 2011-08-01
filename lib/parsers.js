(function() {
  /*
  Syntax tree parsers
  ===================
  
  These classes provide provide methods for extracting classes and functions from
  the CoffeeScript AST. Each class is specific to a module loading system (e.g.
  CommonJS, RequireJS), and should implement the `getClasses` and `getFunctions`
  methods. These methods return an array of class nodes and function nodes
  respectively. Parsers are selected via command line option.
  */  var CommonJSParser, RequireJSParser;
  exports.CommonJSParser = CommonJSParser = (function() {
    function CommonJSParser() {}
    /*
        Parses code written according to CommonJS specifications:
    
            require("module")
            exports.func = ->
        */
    CommonJSParser.prototype.getClasses = function(nodes) {
      var n, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        n = nodes[_i];
        if (n.type === 'Class' || n.type === 'Assign' && n.value.type === 'Class') {
          _results.push(n);
        }
      }
      return _results;
    };
    CommonJSParser.prototype.getFunctions = function(nodes) {
      var n, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        n = nodes[_i];
        if (n.type === 'Assign' && n.value.type === 'Code') {
          _results.push(n);
        }
      }
      return _results;
    };
    return CommonJSParser;
  })();
  exports.RequireJSParser = RequireJSParser = (function() {
    function RequireJSParser() {}
    /*
        Not yet implemented
        */
    RequireJSParser.prototype.getClasses = function(nodes) {
      throw 'RequireJS parser not yet implemented';
    };
    RequireJSParser.prototype.getFunctions = function(nodes) {
      throw 'RequireJS parser not yet implemented';
    };
    return RequireJSParser;
  })();
}).call(this);
