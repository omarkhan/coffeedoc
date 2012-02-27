fs = require 'fs'
path = require 'path'
eco = require('eco')

class Render
  constructor: (@outputdir, @sources) ->

  renderIndex: (modules) ->
    eco.render @index_template, modules: modules

  renderModule: (ctx) ->
    ctx.wikiize = wikiize
    ctx.quoteMarkdown = quoteMarkdown
    eco.render @module_template, ctx

  shouldMakeSubdirs: -> true
  moduleFilename: (x) -> x
  setup: ->
  finish: ->
  fileExtension: -> '.html'
  indexFile: -> 'index.html'

class HtmlRender extends Render
  constructor: (@outputdir, @sources) ->
    @module_template = fs.readFileSync(__dirname + '/../resources/html/module.eco', 'utf-8')
    @index_template = fs.readFileSync(__dirname + '/../resources/html/index.eco', 'utf-8')
    @base_css = fs.readFileSync(__dirname + '/../resources/html/base.css', 'utf-8')
    @module_css = fs.readFileSync(__dirname + '/../resources/html/module.css', 'utf-8')
    @index_css = fs.readFileSync(__dirname + '/../resources/html/index.css', 'utf-8')

  setup: ->

  finish: ->
    ###
    Writes CSS files out to resources
    ###
    resourcesdir = path.join(@outputdir, 'resources')
    fs.mkdir resourcesdir, '755', ->
        fs.writeFile(path.join(resourcesdir, 'base.css'), @base_css)
        fs.writeFile(path.join(resourcesdir, 'module.css'), @module_css)
        fs.writeFile(path.join(resourcesdir, 'index.css'), @index_css)


class GithubWikiRender extends Render
  constructor: (@outputdir, @sources) ->
    @module_template = fs.readFileSync(__dirname + '/../resources/github-wiki/module.eco', 'utf-8')
    @index_template = fs.readFileSync(__dirname + '/../resources/github-wiki/index.eco', 'utf-8')

  moduleFilename: (x) ->
    wikiize x

  fileExtension: -> '.md'
  indexFile: -> 'ModuleIndex.md'
  shouldMakeSubdirs: -> false


wikiize = (path) ->
    bits = path.split('/')
    bucket = []
    for b in bits
      if b
        bucket.push "#{b[0].toUpperCase()}#{b.substring 1}"
    bucket.join(':')

quoteMarkdown = (t) ->
    ###
    Its more than possible that a function name will have underscores... quote them.
    ###
    t.replace /([^\\])?_/g, "$1\\_"


exports.GithubWikiRender = GithubWikiRender
exports.Render = Render
exports.HtmlRender = HtmlRender