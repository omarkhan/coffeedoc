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

# Get source file paths
sources = []
getSourceFiles = (target) ->
    if path.extname(target) == '.coffee'
        sources.push(target)
    else if fs.statSync(target).isDirectory()
        getSourceFiles(path.join(target, p)) for p in fs.readdirSync(target)
getSourceFiles(o) for o in opts

if sources.length > 0
    modules = []
    
    # Make `docs/` directory under current dir
    if path.existsSync('docs')
        # Recursively delete `docs/` if it already exists
        rm = (target) ->
            if fs.statSync(target).isDirectory()
                rm(path.join(target, p)) for p in fs.readdirSync(target)
                fs.rmdirSync(target)
            else
                fs.unlinkSync(target)
        rm('docs')
    fs.mkdirSync('docs', '755')

    # Iterate over source scripts
    source_names = (s.replace(/\.coffee$/, '') for s in sources)
    for source, idx in sources
        script = fs.readFileSync(source, 'utf-8')

        # If source is in a subfolder, make a matching subfolder in `docs/`
        csspath = 'resources/'
        if source.indexOf('/') != -1
            docpath = 'docs'
            sourcepath = source.split('/')
            for dir in sourcepath[0...sourcepath.length - 1]
                csspath = '../' + csspath
                docpath = path.join(docpath, dir)
                if not path.existsSync(docpath)
                    fs.mkdirSync(docpath, '755')

        # Fetch documentation information
        documentation =
            filename: source_names[idx] + '.html'
            module_name: path.basename(source)
            module: coffeedoc.documentModule(script, parser)
            csspath: csspath

        # Check for classes inheriting from classes in other modules
        for cls in documentation.module.classes when cls.parent
            clspath = cls.parent.split('.')
            if clspath.length > 1
                prefix = clspath.shift()
                if prefix of documentation.module.deps
                    module_path = documentation.module.deps[prefix]
                    if module_path in source_names
                        cls.parent_module = module_path
                        cls.parent_name = clspath.join('.')

        # Convert markdown to html
        renderMarkdown(documentation.module)
        for c in documentation.module.classes
            renderMarkdown(c)
            renderMarkdown(m) for m in c.staticmethods
            renderMarkdown(m) for m in c.instancemethods
        renderMarkdown(f) for f in documentation.module.functions

        # Generate docs
        html = eco.render(module_template, documentation)

        # Write to file
        fs.writeFile(path.join('docs', documentation.filename), html)

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

