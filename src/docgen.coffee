###
Documentation generator
=======================

This script generates html documentation from a coffeescript source file
###

# Imports
fs = require('fs')
path = require('path')
coffeedoc = require(__dirname + '/coffeedoc')
parsers = require(__dirname + '/parsers')
renderers = require(__dirname + '/renderers')

# Command line options
opts = require('optimist')
    .usage('''Usage: coffeedoc [options] [targets]''')
    .describe('output', 'Set output directory (default: ./docs)')
    .default('output', 'docs')
    .alias('o', 'output')
    .describe('parser', "Parser to use. Available parsers: #{Object.keys(parsers)}")
    .default('parser', 'commonjs')
    .describe('renderer', "Renderer to use. Available renderers: #{Object.keys(renderers)}")
    .default('renderer', 'html')
    .describe('stdout', 'Direct all output to stdout instead of files')
    .boolean('stdout')
    .describe('help', 'Show this help.')
    .alias('h', 'help')

argv = opts.argv

if argv.help or argv._.length == 0
    opts.showHelp()
    process.exit()

rendercls = renderers[argv.renderer]
if not rendercls?
    console.error "Invalid renderer: #{argv.renderer}\n"
    opts.showHelp()
    process.exit()

parsercls = parsers[argv.parser]
if not parsercls?
    console.error "Invalid parser: #{argv.parser}\n"
    opts.showHelp()
    process.exit()

parser = new parsercls()

# Get source file paths
sources = []
getSourceFiles = (target) ->
    if path.extname(target) == '.coffee'
        sources.push(target)
    else if fs.statSync(target).isDirectory()
        getSourceFiles(path.join(target, p)) for p in fs.readdirSync(target)
getSourceFiles(o) for o in argv._
sources.sort()

renderer = new rendercls(argv.output, sources)

if sources.length > 0
    modules = []

    # Set up output functions
    if argv.stdout
        output = (path, data) -> process.stdout.write data
    else
        output = (path, data) -> fs.writeFile path, data

        # Make output directory
        if path.existsSync(argv.output)
            # Recursively delete argv.output if it already exists
            rm = (target) ->
                if fs.statSync(target).isDirectory()
                    rm(path.join(target, p)) for p in fs.readdirSync(target)
                    fs.rmdirSync(target)
                else
                    fs.unlinkSync(target)
            rm(argv.output)
        fs.mkdirSync(argv.output, '755')

    # Iterate over source scripts
    source_names = (s.replace(/\.coffee$/, '') for s in sources)

    for source, idx in sources
        script = fs.readFileSync(source, 'utf-8')

        resourcepath = 'resources/'
        if source.indexOf('/') != -1 and renderer.shouldMakeSubdirs()
            docpath = argv.output
            sourcepath = source.split('/')
            for dir in sourcepath[0...sourcepath.length - 1]
                resourcepath = '../' + resourcepath
                docpath = path.join(docpath, dir)
                if not path.existsSync(docpath)
                    fs.mkdirSync(docpath, '755')


        # Fetch documentation information
        documentation =
            filename: renderer.moduleFilename(source_names[idx])
            module_name: path.basename(source)
            qualified_name: source
            module: coffeedoc.documentModule(script, parser)
            resourcepath: resourcepath

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

        # If there is no filename do not output this modules documentation
        if documentation.filename
          # Generate docs for current module
          result = renderer.renderModule(documentation)
          output(path.join(argv.output, documentation.filename + renderer.fileExtension()), result)

        # Save to modules array for the index page
        modules.push(documentation)


    # Make index page
    index = renderer.renderIndex(modules)
    output(path.join(argv.output, renderer.indexFile()), index)
    renderer.finish()
