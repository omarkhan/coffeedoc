(function() {
  /*
  Documentation generator
  =======================
  This script generates html documentation from a coffeescript source file
  */  var coffeedoc, css, eco, fs, path, renderMarkdown, showdown, sources, template;
  fs = require('fs');
  path = require('path');
  eco = require('eco');
  showdown = require(__dirname + '/showdown').Showdown;
  coffeedoc = require(__dirname + '/coffeedoc');
  renderMarkdown = function(obj) {
    /*
        Helper function that transforms markdown docstring within an AST node
        into html, in place
        */    if (obj.docstring) {
      obj.docstring = showdown.makeHtml(obj.docstring);
    }
    return null;
  };
  template = fs.readFileSync(__dirname + '/../resources/coffeedoc.eco', 'utf-8');
  css = fs.readFileSync(__dirname + '/../resources/coffeedoc.css', 'utf-8');
  sources = process.argv.slice(2, process.argv.length);
  if (sources.length > 0) {
    fs.mkdir('docs', '755', function() {
      var c, documentation, f, html, m, script, source, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _results;
      _results = [];
      for (_i = 0, _len = sources.length; _i < _len; _i++) {
        source = sources[_i];
        script = fs.readFileSync(source, 'utf-8');
        documentation = {
          module_name: path.basename(source),
          module: coffeedoc.documentModule(script)
        };
        renderMarkdown(documentation.module);
        _ref = documentation.module.classes;
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          c = _ref[_j];
          renderMarkdown(c);
          _ref2 = c.methods;
          for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
            m = _ref2[_k];
            renderMarkdown(m);
          }
        }
        _ref3 = documentation.module.functions;
        for (_l = 0, _len4 = _ref3.length; _l < _len4; _l++) {
          f = _ref3[_l];
          renderMarkdown(f);
        }
        html = eco.render(template, documentation);
        _results.push(fs.writeFile('docs/' + path.basename(source, path.extname(source)) + '.html', html));
      }
      return _results;
    });
    fs.mkdir('docs/resources', '755', function() {
      return fs.writeFile('docs/resources/coffeedoc.css', css);
    });
  }
}).call(this);
