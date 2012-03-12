fs = require('fs')
path = require('path')
eco = require('eco')
showdown = require(__dirname + '/../vendor/showdown').Showdown

class Renderer
    constructor: (outputdir, sources) ->
        this.outputdir = outputdir
        this.sources = sources

    renderIndex: (modules) =>
        eco.render(this.index_template, modules: modules)

    renderModule: (context) =>
        eco.render(this.module_template, context)

    shouldMakeSubdirs: -> true
    moduleFilename: (x) -> x
    finish: ->

class HtmlRenderer extends Renderer
    constructor: (outputdir, sources) ->
        super(outputdir, sources)
        this.module_template = fs.readFileSync(__dirname + '/../resources/html/module.eco', 'utf-8')
        this.index_template = fs.readFileSync(__dirname + '/../resources/html/index.eco', 'utf-8')
        this.base_css = fs.readFileSync(__dirname + '/../resources/html/base.css', 'utf-8')
        this.module_css = fs.readFileSync(__dirname + '/../resources/html/module.css', 'utf-8')
        this.index_css = fs.readFileSync(__dirname + '/../resources/html/index.css', 'utf-8')

    _renderMarkdown: (obj) ->
        ###
        Helper function that transforms markdown docstring within an AST node
        into html, in place
        ###
        if obj.docstring
            obj.docstring = showdown.makeHtml(obj.docstring)
        return null

    renderModule: (context) =>
        # Convert markdown to html
        this._renderMarkdown(context.module)
        for c in context.module.classes
            this._renderMarkdown(c)
            this._renderMarkdown(m) for m in c.staticmethods
            this._renderMarkdown(m) for m in c.instancemethods
        this._renderMarkdown(f) for f in context.module.functions
        super(context)

    finish: =>
        ###
        Writes CSS files out to resources
        ###
        resourcesdir = path.join(this.outputdir, 'resources')
        fs.mkdir resourcesdir, '755', =>
            fs.writeFile(path.join(resourcesdir, 'base.css'), this.base_css)
            fs.writeFile(path.join(resourcesdir, 'module.css'), this.module_css)
            fs.writeFile(path.join(resourcesdir, 'index.css'), this.index_css)

    fileExtension: -> '.html'
    indexFile: -> 'index.html'

class GithubWikiRenderer extends Renderer
    constructor: (outputdir, sources) ->
        super(outputdir, sources)
        this.module_template = fs.readFileSync(__dirname + '/../resources/github-wiki/module.eco', 'utf-8')
        this.index_template = fs.readFileSync(__dirname + '/../resources/github-wiki/index.eco', 'utf-8')

    _wikiize: (path) ->
        bits = path.split('/')
        bucket = []
        for b in bits
            if b
                bucket.push "#{b[0].toUpperCase()}#{b.substring 1}"
        bucket.join(':')

    _quoteMarkdown: (t) ->
        ###
        Its more than possible that a function name will have underscores... quote them.
        ###
        t.replace(/([^\\])?_/g, "$1\\_")

    _params: (t) ->
        a = []
        for x in t
            if x?
               a.push x
            else
               a.push '{splat}'
        a.join ', '

    moduleFilename: (x) =>
        return this._wikiize(x)

    renderModule: (context) =>
        context.wikiize = this._wikiize
        context.quoteMarkdown = this._quoteMarkdown
        context.params = this._params
        super(context)

    fileExtension: -> '.md'
    indexFile: -> 'ModuleIndex.md'
    shouldMakeSubdirs: -> false


exports.GithubWikiRenderer = GithubWikiRenderer
exports.HtmlRenderer = HtmlRenderer
