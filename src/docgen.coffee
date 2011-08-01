###
Documentation generator
=======================
This script generates html documentation from a coffeescript source file
###

fs = require('fs')
path = require('path')
eco = require('eco')
showdown = require(__dirname + '/../vendor/showdown').Showdown
coffeedoc = require(__dirname + '/coffeedoc')
parsers = require(__dirname + '/parsers')

renderMarkdown = (obj) ->
    ###
    Helper function that transforms markdown docstring within an AST node
    into html, in place
    ###
    if obj.docstring
        obj.docstring = showdown.makeHtml(obj.docstring)
    return null

# Fetch resources
module_template = fs.readFileSync(__dirname + '/../resources/module.eco', 'utf-8')
index_template = fs.readFileSync(__dirname + '/../resources/index.eco', 'utf-8')
base_css = fs.readFileSync(__dirname + '/../resources/base.css', 'utf-8')
module_css = fs.readFileSync(__dirname + '/../resources/module.css', 'utf-8')
index_css = fs.readFileSync(__dirname + '/../resources/index.css', 'utf-8')

# Command line options
OPTIONS =
    '--commonjs': ' Use if target scripts use CommonJS for module loading (default)'
    '--requirejs': 'Use if target scripts use RequireJS for module loading'

opts = process.argv[2...process.argv.length]
if opts.length == 0
    console.log('Usage: coffeedoc [options] targets\n')
    console.log('Options:')
    for flag, description of OPTIONS
        console.log('    ' + flag + ': ' + description)
    process.exit()
if opts[0] == '--requirejs'
    opts.shift()
    parser = new parsers.RequireJSParser()
else if opts[0] == '--commonjs'
    opts.shift()
    parser = new parsers.CommonJSParser()
else
    parser = new parsers.CommonJSParser()
sources = opts

# Iterate over source scripts
if sources.length > 0
    modules = []
    source_names = (path.basename(s, path.extname(s)) for s in sources)
    
    # Make docs/ directory under current dir
    fs.mkdir 'docs', '755', ->
        for source, idx in sources
            script = fs.readFileSync(source, 'utf-8')

            # Fetch documentation information
            documentation =
                filename: source_names[idx] + '.html'
                module_name: path.basename(source)
                module: coffeedoc.documentModule(script, parser)

            # Check for classes inheriting from classes in other modules
            for cls in documentation.module.classes when cls.parent
                clspath = cls.parent.split('.')
                if clspath.length > 1
                    prefix = clspath.shift()
                    if prefix of documentation.module.deps
                        module_path = documentation.module.deps[prefix]
                        module_filename = path.basename(module_path, path.extname(module_path))
                        if module_filename in source_names
                            cls.parent_module = module_filename
                            cls.parent_name = clspath.join('.')

            # Convert markdown to html
            renderMarkdown(documentation.module)
            for c in documentation.module.classes
                renderMarkdown(c)
                renderMarkdown(m) for m in c.methods
            renderMarkdown(f) for f in documentation.module.functions

            # Generate docs
            html = eco.render(module_template, documentation)

            # Write to file
            fs.writeFile('docs/' + documentation.filename, html)

            # Save to modules array for the index page
            modules.push(documentation)

        # Write css stylesheets to docs/resources/
        fs.mkdir 'docs/resources', '755', ->
            fs.writeFile('docs/resources/base.css', base_css)
            fs.writeFile('docs/resources/module.css', module_css)
            fs.writeFile('docs/resources/index.css', index_css)

        # Make index page
        index = eco.render(index_template, modules: modules)
        fs.writeFile('docs/index.html', index)

