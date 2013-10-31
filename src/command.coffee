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
        .options
            'output':
                describe: 'Set output directory'
                alias: 'o'
                default: 'docs'
            'ignore':
                describe: 'Files or directories to ignore'
                alias: 'i'
            'stdout':
                describe: 'Direct all output to stdout instead of files'
                boolean: true
            'hide-private':
                describe: 'Do not document methods beginning with an underscore'
                boolean: true
            'parser':
                describe: "Parser to use. Built-in parsers: #{Object.keys(parsers).join(', ')}"
                default: 'commonjs'
            'renderer':
                describe: "Renderer to use. Built-in renderers: #{Object.keys(renderers).join(', ')}"
                default: 'html'
            'indexTemplate':
                describe: 'Override the default index template for the selected renderer'
            'moduleTemplate':
                describe: 'Override the default module template for the selected renderer'
            'help':
                describe: 'Show this help and exit'
                alias: 'h'

    argv = opts.argv

    if argv.help or argv._.length == 0
        opts.showHelp()
        process.exit()

    # Instantiate the renderer
    rendercls = renderers[argv.renderer] or require(argv.renderer)
    if not rendercls?
        console.error "Invalid renderer: #{argv.renderer}\n"
        opts.showHelp()
        process.exit()
    rendererOpts = { hideprivate: argv['hide-private'] }
    if argv.indexTemplate
        rendererOpts.indexTemplate = fs.readFileSync(argv.indexTemplate, 'utf-8')
    if argv.moduleTemplate
        rendererOpts.moduleTemplate = fs.readFileSync(argv.moduleTemplate, 'utf-8')
    renderer = new rendercls(rendererOpts)

    # Instantiate the parser
    parsercls = parsers[argv.parser] or require(argv.parser)
    if not parsercls?
        console.error "Invalid parser: #{argv.parser}\n"
        opts.showHelp()
        process.exit()
    parser = new parsercls()

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

    # Generate the index page. If no output dir is given, write it to stdout
    # and exit.
    index = renderer.renderIndex(modules)
    if not argv.output
        process.stdout.write(index)
        process.exit()

    # Create output directory, recursively deleting it if it already exists.
    if fs.existsSync(argv.output)
        rm = (target) ->
            if fs.statSync(target).isDirectory()
                rm(path.join(target, p)) for p in fs.readdirSync(target)
                fs.rmdirSync(target)
            else
                fs.unlinkSync(target)
        rm(argv.output)
    fs.mkdirSync(argv.output, '755')

    # Write the index page.
    fs.writeFile(path.join(argv.output, renderer.indexFile + renderer.extension), index)

    # Write documentation for each module.
    renderer.writeModules(modules, argv.output)
