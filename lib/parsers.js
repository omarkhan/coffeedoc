(function() {
  /*
  Syntax tree parsers
  ===================
  
  These classes provide provide methods for extracting classes and functions from
  the CoffeeScript AST. Each parser class is specific to a module loading system
  (e.g.  CommonJS, RequireJS), and should implement the `getDependencies`,
  `getClasses` and `getFunctions` methods. Parsers are selected via command line
  option.
  */  var BaseParser, CommonJSParser, RequireJSParser;
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
  BaseParser = (function() {
    function BaseParser() {}
    /*
        This base class defines the interface for parsers. Subclasses should
        implement these methods.
        */
    BaseParser.prototype.getNodes = function(root_node) {
      /*
              Traverse the AST, adding a 'type' attribute to each node containing the
              name of the node's constructor, and return the expressions array
              */      return null;
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
    CommonJSParser.prototype.getNodes = function(root_node) {
      root_node.traverseChildren(false, function(node) {
        return node.type = node.constructor.name;
      });
      return root_node.expressions;
    };
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
    RequireJSParser.prototype.getNodes = function(root_node) {
      var moduleLdrs, nodes;
      nodes = [];
      moduleLdrs = ['define', 'require'];
      root_node.traverseChildren(false, function(node) {
        var arg, _i, _len, _ref, _ref2, _results;
        node.type = node.constructor.name;
        node.level = 1;
        if (node.type === 'Call' && (_ref = node.variable.base.value, __indexOf.call(moduleLdrs, _ref) >= 0)) {
          _ref2 = node.args;
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            arg = _ref2[_i];
            _results.push(arg.constructor.name === 'Code' ? (arg.body.traverseChildren(false, function(node) {
              node.type = node.constructor.name;
              return node.level = 2;
            }), nodes = nodes.concat(arg.body.expressions)) : void 0);
          }
          return _results;
        }
      });
      return root_node.expressions.concat(nodes);
    };
    RequireJSParser.prototype._parseDefine = function(node, deps) {};
    RequireJSParser.prototype._parseRequire = function(node, deps) {};
    RequireJSParser.prototype._parseAssign = function(node, deps) {
      var arg, local_name, module_path;
      arg = node.value.args[0];
      module_path = this._getModulePath(arg);
      if (module_path != null) {
        local_name = this._getFullName(node.variable);
        return deps[local_name] = module_path;
      }
    };
    RequireJSParser.prototype._parseObject = function(node, deps) {
      var arg, args, attr, func, index, local_name, mod, mod_path, mods, obj, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _results;
      obj = node.value.base;
      mods = [];
      args = [];
      _ref = obj.properties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        if (attr.variable.base.value === 'deps' && attr.value.base.type === 'Arr') {
          _ref2 = attr.value.base.objects;
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            mod = _ref2[_j];
            mod_path = this._getModulePath(mod);
            if (mod_path != null) {
              mods.push(mod_path);
            }
          }
        } else if (attr.variable.base.value === 'callback' && attr.value.base.body.expressions[0].type === 'Code') {
          func = attr.value.base.body.expressions[0];
          _ref3 = func.params;
          for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
            arg = _ref3[_k];
            args.push(arg.name.value);
          }
        }
      }
      index = 0;
      _results = [];
      for (_l = 0, _len4 = mods.length; _l < _len4; _l++) {
        mod = mods[_l];
        local_name = index < args.length ? args[index] : mod;
        deps[local_name] = mod;
        _results.push(index++);
      }
      return _results;
    };
    RequireJSParser.prototype._stripQuotes = function(str) {
      return str.replace(/('|\")/g, '');
    };
    RequireJSParser.prototype._getModulePath = function(mod) {
      if (mod.type === 'Value') {
        return this._stripQuotes(mod.base.value);
      } else if (mod.type === 'Op' && mod.operator === '+') {
        return '.' + this._stripQuotes(mod.second.base.value);
      }
      return null;
    };
    RequireJSParser.prototype._getFullName = function(variable) {
      var name, p;
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
    RequireJSParser.prototype.getDependencies = function(nodes) {
      /*
              This currently works with the following `require` calls:
      
                  local_name = require("path/to/module")
                  local_name = require(__dirname + "/path/to/module")
      
              And the following `require` object assignments:
      
                  require = {deps: ["path/to/module"]}
                  require = {deps: ["path/to/module"], callback: (module) ->}
      
              NOTE: require([], ->) and define([], ->) are not yet implemented
              */      var deps, n, _i, _len;
      deps = {};
      for (_i = 0, _len = nodes.length; _i < _len; _i++) {
        n = nodes[_i];
        if (n.type === 'Call') {
          if (n.variable.base.value === 'define') {
            this._parseDefine(n, deps);
          } else if (n.variable.base.value === 'require') {
            this._parseRequire(n, deps);
          }
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
