###
Documentation generator
=======================

This script generates html documentation from a coffeescript source file
###

# Imports
fs = require('fs')
path = require('path')
eco = require('eco')
coffeedoc = require(__dirname + '/coffeedoc')
parsers = require(__dirname + '/parsers')


# Command line options
OPTIONS =
    '-o, --output': 'Set output directory (default: ./docs)'
    '--commonjs  ': 'Use if target scripts use CommonJS for module loading (default)'
    '--requirejs ': 'Use if target scripts use RequireJS for module loading'

help = ->
    ### Show help message and exit ###
    console.log('Usage: coffeedoc [options] [targets]\n')
    console.log('Options:')
    for flag, description of OPTIONS
        console.log('    ' + flag + ': ' + description)
    process.exit()

opts = process.argv[2...process.argv.length]
if opts.length == 0 then help()

outputdir = 'docs'
for o, idx in opts
    if o == '-o' or o == '--output'
        outputdir = opts[idx + 1]
        opts.splice(idx, 2)
        break
if '-h' in opts or '--help' in opts
    help()
if '--commonjs' in opts
    opts.shift()
    parser = new parsers.CommonJSParser()
else if '--requirejs' in opts
   opts.shift()
   parser = new parsers.RequireJSParser()
else
    parser = new parsers.CommonJSParser()
if opts.length == 0
    opts = ['.']


# Fetch resources
module_template = fs.readFileSync(__dirname + '/../resources/module.eco', 'utf-8')
index_template = fs.readFileSync(__dirname + '/../resources/index.eco', 'utf-8')


# Get source file paths
sources = []
getSourceFiles = (target) ->
    if path.extname(target) == '.coffee'
        sources.push(target)
    else if fs.statSync(target).isDirectory()
        getSourceFiles(path.join(target, p)) for p in fs.readdirSync(target)
getSourceFiles(o) for o in opts

wikiize = (path) ->
    bits = path.split('/')
    bucket = []
    for b in bits
      bucket.push "#{b[0].toUpperCase()}#{b.substring 1}"
    console.log bucket
    bucket.join(':')

if sources.length > 0
    modules = []
    

    # Make output directory

    if path.existsSync(outputdir)
        # Recursively delete outputdir if it already exists
        rm = (target) ->
            if fs.statSync(target).isDirectory()
                rm(path.join(target, p)) for p in fs.readdirSync(target)
                fs.rmdirSync(target)
            else
                fs.unlinkSync(target)
        rm(outputdir)
    fs.mkdirSync(outputdir, '755')

    # Iterate over source scripts
    source_names = (s.replace(/\.coffee$/, '') for s in sources)
    for source, idx in sources
        script = fs.readFileSync(source, 'utf-8')

        console.log source_names[idx]

        # Fetch documentation information
        documentation =
            filename: wikiize source_names[idx]
            module_name: path.basename(source)
            qualified_name: source
            module: coffeedoc.documentModule(script, parser)

        # Check for classes inheriting from classes in other modules
        for cls in documentation.module.classes when cls.parent
            clspath = cls.parent.split('.')
            if clspath.length > 1
                prefix = clspath.shift()
                if prefix of documentation.module.deps
                    module_path = documentation.module.deps[prefix]
                    if path.dirname(source) + '/' + module_path in source_names
                        cls.parent_module = module_path
                        cls.parent_name = clspath.join('.')

        documentation['wikiize'] = wikiize

        # Generate docs
        md = eco.render(module_template, documentation)
  
        # Write to file
        fs.writeFile(path.join(outputdir, documentation.filename + '.md'), md)

        # Save to modules array for the index page
        modules.push(documentation)


    # Make index page
    index = eco.render(index_template, modules: modules)
    fs.writeFile(path.join(outputdir, 'ModuleIndex.md'), index)

