(function() {
  /*
  Documentation generator
  =======================
  
  This script generates html documentation from a coffeescript source file
  */  var OPTIONS, base_css, coffeedoc, description, eco, flag, fs, index_css, index_template, module_css, module_template, modules, opts, parser, parsers, path, renderMarkdown, s, showdown, source_names, sources;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  fs = require('fs');
  path = require('path');
  eco = require('eco');
  showdown = require(__dirname + '/../vendor/showdown').Showdown;
  coffeedoc = require(__dirname + '/coffeedoc');
  parsers = require(__dirname + '/parsers');
  renderMarkdown = function(obj) {
    /*
        Helper function that transforms markdown docstring within an AST node
        into html, in place
        */    if (obj.docstring) {
      obj.docstring = showdown.makeHtml(obj.docstring);
    }
    return null;
  };
  module_template = fs.readFileSync(__dirname + '/../resources/module.eco', 'utf-8');
  index_template = fs.readFileSync(__dirname + '/../resources/index.eco', 'utf-8');
  base_css = fs.readFileSync(__dirname + '/../resources/base.css', 'utf-8');
  module_css = fs.readFileSync(__dirname + '/../resources/module.css', 'utf-8');
  index_css = fs.readFileSync(__dirname + '/../resources/index.css', 'utf-8');
  OPTIONS = {
    '--commonjs': ' Use if target scripts use CommonJS for module loading (default)',
    '--requirejs': 'Use if target scripts use RequireJS for module loading'
  };
  opts = process.argv.slice(2, process.argv.length);
  if (opts.length === 0) {
    console.log('Usage: coffeedoc [options] targets\n');
    console.log('Options:');
    for (flag in OPTIONS) {
      description = OPTIONS[flag];
      console.log('    ' + flag + ': ' + description);
    }
    process.exit();
  }
  if (opts[0] === '--requirejs') {
    opts.shift();
    parser = new parsers.RequireJSParser();
  } else if (opts[0] === '--commonjs') {
    opts.shift();
    parser = new parsers.CommonJSParser();
  } else {
    parser = new parsers.CommonJSParser();
  }
  sources = opts;
  if (sources.length > 0) {
    modules = [];
    source_names = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = sources.length; _i < _len; _i++) {
        s = sources[_i];
        _results.push(path.basename(s, path.extname(s)));
      }
      return _results;
    })();
    fs.mkdir('docs', '755', function() {
      var c, cls, clspath, documentation, f, html, idx, index, m, module_filename, module_path, prefix, script, source, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _ref, _ref2, _ref3, _ref4;
      for (idx = 0, _len = sources.length; idx < _len; idx++) {
        source = sources[idx];
        script = fs.readFileSync(source, 'utf-8');
        documentation = {
          filename: source_names[idx] + '.html',
          module_name: path.basename(source),
          module: coffeedoc.documentModule(script, parser)
        };
        _ref = documentation.module.classes;
        for (_i = 0, _len2 = _ref.length; _i < _len2; _i++) {
          cls = _ref[_i];
          if (cls.parent) {
            clspath = cls.parent.split('.');
            if (clspath.length > 1) {
              prefix = clspath.shift();
              if (prefix in documentation.module.deps) {
                module_path = documentation.module.deps[prefix];
                module_filename = path.basename(module_path, path.extname(module_path));
                if (__indexOf.call(source_names, module_filename) >= 0) {
                  cls.parent_module = module_filename;
                  cls.parent_name = clspath.join('.');
                }
              }
            }
          }
        }
        renderMarkdown(documentation.module);
        _ref2 = documentation.module.classes;
        for (_j = 0, _len3 = _ref2.length; _j < _len3; _j++) {
          c = _ref2[_j];
          renderMarkdown(c);
          _ref3 = c.methods;
          for (_k = 0, _len4 = _ref3.length; _k < _len4; _k++) {
            m = _ref3[_k];
            renderMarkdown(m);
          }
        }
        _ref4 = documentation.module.functions;
        for (_l = 0, _len5 = _ref4.length; _l < _len5; _l++) {
          f = _ref4[_l];
          renderMarkdown(f);
        }
        html = eco.render(module_template, documentation);
        fs.writeFile('docs/' + documentation.filename, html);
        modules.push(documentation);
      }
      fs.mkdir('docs/resources', '755', function() {
        fs.writeFile('docs/resources/base.css', base_css);
        fs.writeFile('docs/resources/module.css', module_css);
        return fs.writeFile('docs/resources/index.css', index_css);
      });
      index = eco.render(index_template, {
        modules: modules
      });
      return fs.writeFile('docs/index.html', index);
    });
  }
}).call(this);
