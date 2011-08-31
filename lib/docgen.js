(function() {
  /*
  Documentation generator
  =======================
  
  This script generates html documentation from a coffeescript source file
  */
  var OPTIONS, base_css, c, cls, clspath, coffeedoc, csspath, description, dir, docpath, documentation, eco, f, flag, fs, getSourceFiles, html, idx, index, index_css, index_template, m, module_css, module_path, module_template, modules, o, opts, parser, parsers, path, prefix, renderMarkdown, rm, s, script, showdown, source, source_names, sourcepath, sources, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _len6, _len7, _len8, _m, _n, _o, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
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
  sources = [];
  getSourceFiles = function(target) {
    var p, _i, _len, _ref, _results;
    if (path.extname(target) === '.coffee') {
      return sources.push(target);
    } else if (fs.statSync(target).isDirectory()) {
      _ref = fs.readdirSync(target);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        _results.push(getSourceFiles(path.join(target, p)));
      }
      return _results;
    }
  };
  for (_i = 0, _len = opts.length; _i < _len; _i++) {
    o = opts[_i];
    getSourceFiles(o);
  }
  if (sources.length > 0) {
    modules = [];
    if (path.existsSync('docs')) {
      rm = function(target) {
        var p, _j, _len2, _ref;
        if (fs.statSync(target).isDirectory()) {
          _ref = fs.readdirSync(target);
          for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
            p = _ref[_j];
            rm(path.join(target, p));
          }
          return fs.rmdirSync(target);
        } else {
          return fs.unlinkSync(target);
        }
      };
      rm('docs');
    }
    fs.mkdirSync('docs', '755');
    source_names = (function() {
      var _j, _len2, _results;
      _results = [];
      for (_j = 0, _len2 = sources.length; _j < _len2; _j++) {
        s = sources[_j];
        _results.push(s.replace(/\.coffee$/, ''));
      }
      return _results;
    })();
    for (idx = 0, _len2 = sources.length; idx < _len2; idx++) {
      source = sources[idx];
      script = fs.readFileSync(source, 'utf-8');
      csspath = 'resources/';
      if (source.indexOf('/') !== -1) {
        docpath = 'docs';
        sourcepath = source.split('/');
        _ref = sourcepath.slice(0, sourcepath.length - 1);
        for (_j = 0, _len3 = _ref.length; _j < _len3; _j++) {
          dir = _ref[_j];
          csspath = '../' + csspath;
          docpath = path.join(docpath, dir);
          if (!path.existsSync(docpath)) {
            fs.mkdirSync(docpath, '755');
          }
        }
      }
      documentation = {
        filename: source_names[idx] + '.html',
        module_name: path.basename(source),
        module: coffeedoc.documentModule(script, parser),
        csspath: csspath
      };
      _ref2 = documentation.module.classes;
      for (_k = 0, _len4 = _ref2.length; _k < _len4; _k++) {
        cls = _ref2[_k];
        if (cls.parent) {
          clspath = cls.parent.split('.');
          if (clspath.length > 1) {
            prefix = clspath.shift();
            if (prefix in documentation.module.deps) {
              module_path = documentation.module.deps[prefix];
              if (__indexOf.call(source_names, module_path) >= 0) {
                cls.parent_module = module_path;
                cls.parent_name = clspath.join('.');
              }
            }
          }
        }
      }
      renderMarkdown(documentation.module);
      _ref3 = documentation.module.classes;
      for (_l = 0, _len5 = _ref3.length; _l < _len5; _l++) {
        c = _ref3[_l];
        renderMarkdown(c);
        _ref4 = c.staticmethods;
        for (_m = 0, _len6 = _ref4.length; _m < _len6; _m++) {
          m = _ref4[_m];
          renderMarkdown(m);
        }
        _ref5 = c.instancemethods;
        for (_n = 0, _len7 = _ref5.length; _n < _len7; _n++) {
          m = _ref5[_n];
          renderMarkdown(m);
        }
      }
      _ref6 = documentation.module.functions;
      for (_o = 0, _len8 = _ref6.length; _o < _len8; _o++) {
        f = _ref6[_o];
        renderMarkdown(f);
      }
      html = eco.render(module_template, documentation);
      fs.writeFile(path.join('docs', documentation.filename), html);
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
    fs.writeFile('docs/index.html', index);
  }
}).call(this);
