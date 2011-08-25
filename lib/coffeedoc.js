(function() {
  /*
  Documentation functions
  =======================
  
  These functions extract relevant documentation info from AST nodes as returned
  by the coffeescript parser.
  */
  var documentClass, documentFunction, formatDocstring, getFullName, getNodes, helpers;
  helpers = require(__dirname + '/helpers');
  getNodes = helpers.getNodes;
  getFullName = helpers.getFullName;
  exports.documentModule = function(script, parser) {
    /*
        Given a module's source code and an AST parser, returns module information
        in the form:
    
            {
                "docstring": "Module docstring",
                "classes": [class1, class1...],
                "functions": [func1, func2...]
            }
    
        AST parsers are defined in the `parsers.coffee` module
        */
    var c, doc, docstring, f, first_obj, nodes;
    nodes = getNodes(script);
    first_obj = nodes[0];
    if ((first_obj != null ? first_obj.type : void 0) === 'Comment') {
      docstring = formatDocstring(first_obj.comment);
    } else {
      docstring = null;
    }
    doc = {
      docstring: docstring,
      deps: parser.getDependencies(nodes),
      classes: (function() {
        var _i, _len, _ref, _results;
        _ref = parser.getClasses(nodes);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          c = _ref[_i];
          _results.push(documentClass(c));
        }
        return _results;
      })(),
      functions: (function() {
        var _i, _len, _ref, _results;
        _ref = parser.getFunctions(nodes);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          f = _ref[_i];
          _results.push(documentFunction(f));
        }
        return _results;
      })()
    };
    return doc;
  };
  documentClass = function(cls) {
    /*
        Evaluates a class object as returned by the coffeescript parser, returning
        an object of the form:
        
            {
                "name": "MyClass",
                "docstring": "First comment following the class definition"
                "parent": "MySuperClass",
                "methods": [method1, method2...]
            }
        */
    var doc, docstring, emptyclass, expr, first_obj, instancemethods, m, method, n, parent, staticmethods, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3, _ref4;
    if (cls.type === 'Assign') {
      cls = cls.value;
    }
    emptyclass = cls.body.expressions.length === 0;
    first_obj = emptyclass ? cls.body.expressions[0] : (_ref = cls.body.expressions[0].base) != null ? _ref.objects[0] : void 0;
    if ((first_obj != null ? first_obj.type : void 0) === 'Comment') {
      docstring = formatDocstring(first_obj.comment);
    } else {
      docstring = null;
    }
    staticmethods = [];
    instancemethods = [];
    _ref2 = cls.body.expressions;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      expr = _ref2[_i];
      if (expr.type === 'Value') {
        _ref3 = (function() {
          var _k, _len2, _ref3, _results;
          _ref3 = expr.base.objects;
          _results = [];
          for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
            n = _ref3[_k];
            if (n.type === 'Assign' && n.value.type === 'Code') {
              _results.push(n);
            }
          }
          return _results;
        })();
        for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
          method = _ref3[_j];
          instancemethods.push(method);
        }
      } else if (expr.type === 'Assign' && expr.value.type === 'Code') {
        if (expr.variable["this"]) {
          staticmethods.push(expr);
        }
      }
    }
    if (cls.parent != null) {
      parent = getFullName(cls.parent);
    } else {
      parent = null;
    }
    doc = {
      name: getFullName(cls.variable),
      docstring: docstring,
      parent: parent,
      staticmethods: (function() {
        var _k, _len3, _results;
        _results = [];
        for (_k = 0, _len3 = staticmethods.length; _k < _len3; _k++) {
          m = staticmethods[_k];
          _results.push(documentFunction(m));
        }
        return _results;
      })(),
      instancemethods: (function() {
        var _k, _len3, _results;
        _results = [];
        for (_k = 0, _len3 = instancemethods.length; _k < _len3; _k++) {
          m = instancemethods[_k];
          _results.push(documentFunction(m));
        }
        return _results;
      })()
    };
    _ref4 = doc.staticmethods;
    for (_k = 0, _len3 = _ref4.length; _k < _len3; _k++) {
      method = _ref4[_k];
      method.name = method.name.replace(/^this/, doc.name);
    }
    return doc;
  };
  documentFunction = function(func) {
    /*
        Evaluates a function object as returned by the coffeescript parser,
        returning an object of the form:
        
            {
                "name": "myFunc",
                "docstring": "First comment following the function definition",
                "params": ["param1", "param2"...]
            }
        */
    var doc, docstring, first_obj, p, params;
    first_obj = func.value.body.expressions[0];
    if (first_obj != null ? first_obj.comment : void 0) {
      docstring = formatDocstring(first_obj.comment);
    } else {
      docstring = null;
    }
    if (func.value.params) {
      params = (function() {
        var _i, _len, _ref, _ref2, _results;
        _ref = func.value.params;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          _results.push(((_ref2 = p.name.base) != null ? _ref2.value : void 0) === 'this' ? '@' + p.name.properties[0].name.value : p.splat ? p.name.value + '...' : p.name.value);
        }
        return _results;
      })();
    } else {
      params = [];
    }
    return doc = {
      name: getFullName(func.variable),
      docstring: docstring,
      params: params
    };
  };
  formatDocstring = function(str) {
    /*
        Given a string, returns it with leading whitespace removed but with
        indentation preserved. Replaces `\\#` with `#` to allow for the use of
        multiple `#` characters in markup languages (e.g. Markdown headers)
        */
    var indentation, leading_whitespace, line, lines;
    lines = str.replace(/\\#/g, '#').split('\n');
    while (/^ *$/.test(lines[0])) {
      lines.shift();
    }
    if (lines.length === 0) {
      return null;
    }
    indentation = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        if (/^ *$/.test(line)) {
          continue;
        }
        _results.push(line.match(/^ */)[0].length);
      }
      return _results;
    })();
    indentation = Math.min.apply(Math, indentation);
    leading_whitespace = new RegExp("^ {" + indentation + "}");
    return ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _results.push(line.replace(leading_whitespace, ''));
      }
      return _results;
    })()).join('\n');
  };
}).call(this);
