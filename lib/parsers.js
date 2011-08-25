(function() {
  /*
  Syntax tree parsers
  ===================
  
  These classes provide provide methods for extracting classes and functions from
  the CoffeeScript AST. Each parser class is specific to a module loading system
  (e.g.  CommonJS, RequireJS), and should implement the `getDependencies`,
  `getClasses` and `getFunctions` methods. Parsers are selected via command line
  option.
  */
  var BaseParser, CommonJSParser, RequireJSParser;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  BaseParser = (function() {
    function BaseParser() {}
    /*
        This base class defines the interface for parsers. Subclasses should
        implement these methods.
        */
    BaseParser.prototype.getDependencies = function(nodes) {
      /*
              Parse require statements and return a hash of module
              dependencies of the form:
      
                  {
                      "local.name": "path/to/module"
                  }
              */      return [];
    };
    BaseParser.prototype.getClasses = function(nodes) {
      /*
              Return an array of class nodes. Be sure to include classes that are
              assigned to variables, e.g. `exports.MyClass = class MyClass`
              */      return [];
    };
    BaseParser.prototype.getFunctions = function(nodes) {
      /*
              Return an array of function nodes.
              */      return [];
    };
    return BaseParser;
  })();
  exports.CommonJSParser = CommonJSParser = (function() {
    var getDependencies;
    __extends(CommonJSParser, BaseParser);
    function CommonJSParser() {
      CommonJSParser.__super__.constructor.apply(this, arguments);
    }
    /*
        Parses code written according to CommonJS specifications:
    
            require("module")
            exports.func = ->
        */
    getDependencies = function(nodes) {
      /*
              This currently works with the following `require` calls:
      
                  local_name = require("path/to/module")
      
              or
      
                  local_name = require(__dirname + "/path/to/module")
      
              In the second example, `__dirname` is replaced with a `.` in the output.
              */
      var arg, deps, local_name, module_path, n, stripQuotes, _i, _len;
      stripQuotes = function(str) {
        return str.replace(/('|\")/g, '');
      };
      deps = {};
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        n = nodes[_i];
        if (n.type === 'Assign') {
          if (n.value.type === 'Call' && n.value.variable.base.value === 'require') {
            arg = n.value.args[0];
            if (arg.type === 'Value') {
              module_path = stripQuotes(arg.base.value);
            } else if (arg.type === 'Op' && arg.operator === '+') {
              module_path = '.' + stripQuotes(arg.second.base.value);
            } else {
              continue;
            }
            local_name = getFullName(n.variable);
            deps[local_name] = module_path;
          }
        }
      }
      return deps;
    };
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
    __extends(RequireJSParser, BaseParser);
    function RequireJSParser() {
      RequireJSParser.__super__.constructor.apply(this, arguments);
    }
    /*
        Not yet implemented
        */
    return RequireJSParser;
  })();
}).call(this);
