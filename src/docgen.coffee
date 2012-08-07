###
Documentation generator
=======================

Process command line options and generate documentation for the given input.
###

exports.run = ->

    # Imports
    fs = require('fs')
    path = require('path')
    coffeedoc = require(__dirname + '/coffeedoc')
    parsers = require(__dirname + '/parsers')
    renderers = require(__dirname + '/renderers')

    # Command line options
    opts = require('optimist')
        .usage('''Usage: coffeedoc [options] [targets]''')
        .describe('output', 'Set output directory')
        .default('output', 'docs')
        .alias('o', 'output')
        .describe('parser', "Parser to use. Available parsers: #{Object.keys(parsers).join(', ')}")
        .default('parser', 'commonjs')
        .describe('renderer', "Renderer to use. Available renderers: #{Object.keys(renderers).join(', ')}")
        .default('renderer', 'html')
        .describe('stdout', 'Direct all output to stdout instead of files')
        .boolean('stdout')
        .describe('ignore', 'Files or directories to ignore')
        .alias('i', 'ignore')
        .describe('help', 'Show this help')
        .alias('h', 'help')
        .describe('hide-private', 'Do not document methods beginning with an underscore')
        .boolean('hide-private')

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

    if argv.stdout
        argv.output = null

    if argv.ignore?
        if Array.isArray(argv.ignore)
            ignore = argv.ignore
        else
            ignore = [argv.ignore]
    else
        ignore = []
    ignore = (path.resolve(i) for i in ignore)

    parser = new parsercls()

    # Get source file paths.
    sources = []
    getSourceFiles = (target) ->
        if path.resolve(target) in ignore
            return
        if path.extname(target) == '.coffee'
            sources.push(target)
        else if fs.statSync(target).isDirectory()
            getSourceFiles(path.join(target, p)) for p in fs.readdirSync(target)
    getSourceFiles(o) for o in argv._
    sources.sort()

    renderer = new rendercls({ hideprivate: argv['hide-private'] })

    # Build a hash with documentation information for each source file.
    modules = []
    moduleNames = (s.replace(/\.coffee$/, '') for s in sources)
    for source, idx in sources
        script = fs.readFileSync(source, 'utf-8')

        # Fetch documentation information.
        module = coffeedoc.documentModule(script, parser)
        module.path = source
        module.basename = path.basename(source)
        
        for cls in module.classes
            # Check for classes inheriting from classes in other modules.
            if cls.parent
                clspath = cls.parent.split('.')
                if clspath.length > 1
                    prefix = clspath.shift()
                else
                    prefix = clspath[0]
                if prefix of module.deps
                    modulepath = module.deps[prefix]
                    if path.join(path.dirname(source), modulepath) in moduleNames
                        cls.parentModule = modulepath
                        cls.parentName = clspath.join('.')

        modules.push(module)

    # Generate the documentation.
    renderer.render(modules, argv.output)
