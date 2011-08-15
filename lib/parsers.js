(function() {
  /*
  Syntax tree parsers
  ===================
  
  These classes provide provide methods for extracting classes and functions from
  the CoffeeScript AST. Each parser class is specific to a module loading system
  (e.g.  CommonJS, RequireJS), and should implement the `getDependencies`,
  `getClasses` and `getFunctions` methods. Parsers are selected via command line
  option.
  */  var BaseParser, CommonJSParser, RequireJSParser, coffeescript, getAttr, getFullName, helpers;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  coffeescript = require('coffee-script');
  helpers = require(__dirname + '/helpers');
  getFullName = helpers.getFullName;
  getAttr = helpers.getAttr;
  BaseParser = (function() {
    function BaseParser() {}
    /*
        This base class defines the interface for parsers. Subclasses should
        implement the `getDependencies`, `getClasses` and `getFunctions` methods
        */
    BaseParser.prototype.getNodes = function(script) {
      /*
              Generates the AST from coffeescript source code.  Adds a 'type' attribute
              to each node containing the name of the node's constructor, and returns
              the expressions array
              */      var root_node;
      root_node = coffeescript.nodes(script);
      root_node.traverseChildren(false, function(node) {
        return node.type = node.constructor.name;
      });
      return root_node.expressions;
    };
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
    __extends(CommonJSParser, BaseParser);
    function CommonJSParser() {
      CommonJSParser.__super__.constructor.apply(this, arguments);
    }
    /*
        Parses code written according to CommonJS specifications:
    
            require("module")
            exports.func = ->
        */
    CommonJSParser.prototype.getDependencies = function(nodes) {
      /*
              This currently works with the following `require` calls:
      
                  local_name = require("path/to/module")
      
              or
      
                  local_name = require(__dirname + "/path/to/module")
      
              In the second example, `__dirname` is replaced with a `.` in the output.
              */      var arg, deps, local_name, module_path, n, stripQuotes, _i, _len;
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
        Parses code written according to RequireJS specifications:
    
            require [], ->
                ... code ...
    
            define [], () ->
                ... code ...
        */
    RequireJSParser.prototype.getNodes = function(script, debug) {
      var moduleLdrs, nodes, root_node;
      if (debug == null) {
        debug = false;
      }
      root_node = coffeescript.nodes(script);
      nodes = [];
      moduleLdrs = ['define', 'require'];
      root_node.traverseChildren(false, function(node) {
        var arg, _i, _len, _ref, _ref2;
        node.type = node.constructor.name;
        node.level = 1;
        if (node.type === 'Call' && (_ref = node.variable.base.value, __indexOf.call(moduleLdrs, _ref) >= 0)) {
          _ref2 = node.args;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            arg = _ref2[_i];
            if (arg.constructor.name === 'Code') {
              arg.body.traverseChildren(false, function(node) {
                node.type = node.constructor.name;
                node.level = 2;
                if (debug) {
                  return console.log(node);
                }
              });
              nodes = nodes.concat(arg.body.expressions);
            }
          }
        }
        if (debug) {
          return console.log(node);
        }
      });
      return root_node.expressions.concat(nodes);
    };
    RequireJSParser.prototype._parseCall = function(node, deps) {
      /* Parse require([], ->) and define([], ->) */      var arg, args, mods, val1, val2, _i, _len, _ref;
      mods = [];
      args = [];
      _ref = node.args;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        arg = _ref[_i];
        val1 = getAttr(arg, 'base');
        val2 = getAttr(arg, 'base.body.expressions[0]');
        if (val1.type === 'Arr') {
          mods = this._parseModuleArray(val1);
        } else if (val2.type === 'Code') {
          args = this._parseFuncArgs(val2);
        } else if (arg.type === 'Code') {
          args = this._parseFuncArgs(arg);
        }
      }
      return this._matchArgs(deps, mods, args);
    };
    RequireJSParser.prototype._parseAssign = function(node, deps) {
      /* Parse module = require("path/to/module") */      var arg, local_name, module_path;
      arg = node.value.args[0];
      module_path = this._getModulePath(arg);
      if (module_path != null) {
        local_name = getFullName(node.variable);
        return deps[local_name] = module_path;
      }
    };
    RequireJSParser.prototype._parseObject = function(node, deps) {
      /* Parse require = {} */      var args, attr, mods, name, obj, val1, val2, _i, _len, _ref;
      obj = node.value.base;
      mods = [];
      args = [];
      _ref = obj.properties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        name = getAttr(attr, 'variable.base.value');
        val1 = getAttr(attr, 'value.base');
        val2 = getAttr(attr, 'value.base.body.expressions[0]');
        if (name === 'deps' && val1.type === 'Arr') {
          mods = this._parseModuleArray(val1);
        } else if (name === 'callback') {
          if (val2.type === 'Code') {
            args = this._parseFuncArgs(val2);
          } else if (attr.value.type === 'Code') {
            args = this._parseFuncArgs(attr.value);
          }
        }
      }
      return this._matchArgs(deps, mods, args);
    };
    RequireJSParser.prototype._matchArgs = function(deps, mods, args) {
      /*
              Match the list of modules to the list of local variable names and
              add them to the dependencies object given.
              */      var index, local_name, mod, _i, _len, _results;
      index = 0;
      _results = [];
      for (_i = 0, _len = mods.length; _i < _len; _i++) {
        mod = mods[_i];
        local_name = index < args.length ? args[index] : mod;
        deps[local_name] = mod;
        _results.push(index++);
      }
      return _results;
    };
    RequireJSParser.prototype._stripQuotes = function(str) {
      return str.replace(/('|\")/g, '');
    };
    RequireJSParser.prototype._parseFuncArgs = function(func) {
      /*
              Given a node of type 'Code', gathers the names of each of the function
              arguments and return them in an array.
              */      var arg, args, _i, _len, _ref;
      args = [];
      _ref = func.params;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        arg = _ref[_i];
        args.push(arg.name.value);
      }
      return args;
    };
    RequireJSParser.prototype._parseModuleArray = function(arr) {
      /*
              Given a node of type 'Arr', gathers the module paths represented by
              each object in the array and returns them in an array.
              */      var mod_path, module, modules, _i, _len, _ref;
      modules = [];
      _ref = arr.objects;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        module = _ref[_i];
        mod_path = this._getModulePath(module);
        if (mod_path != null) {
          modules.push(mod_path);
        }
      }
      return modules;
    };
    RequireJSParser.prototype._getModulePath = function(mod) {
      if (mod.type === 'Value') {
        return this._stripQuotes(mod.base.value);
      } else if (mod.type === 'Op' && mod.operator === '+') {
        return '.' + this._stripQuotes(mod.second.base.value);
      }
      return null;
    };
    RequireJSParser.prototype.getDependencies = function(nodes) {
      /*
              This currently works with the following `require` calls:
      
                  local_name = require("path/to/module")
                  local_name = require(__dirname + "/path/to/module")
      
              The following `require` object assignments:
      
                  require = {deps: ["path/to/module"]}
                  require = {deps: ["path/to/module"], callback: (module) ->}
      
              And the following `require and `define` calls:
      
                  require(["path/to/module"], (module) -> ...)
                  require({}, ["path/to/module"], (module) -> ...)
                  define(["path/to/module"], (module) -> ...)
                  define('', ["path/to/module"], (module) -> ...)
      
              */      var deps, n, _i, _len, _ref;
      deps = {};
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        n = nodes[_i];
        if (n.type === 'Call' && ((_ref = n.variable.base.value) === 'define' || _ref === 'require')) {
          this._parseCall(n, deps);
        } else if (n.type === 'Assign') {
          if (n.value.type === 'Call' && n.value.variable.base.value === 'require') {
            this._parseAssign(n, deps);
          } else if (n.level === 1 && n.variable.base.value === 'require' && n.value.base.type === 'Obj') {
            this._parseObject(n, deps);
          }
        }
      }
      return deps;
    };
    RequireJSParser.prototype.getClasses = function(nodes) {
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
    RequireJSParser.prototype.getFunctions = function(nodes) {
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
    return RequireJSParser;
  })();
}).call(this);
