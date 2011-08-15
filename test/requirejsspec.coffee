fs = require('fs')
parsers = require(__dirname + '/../lib/parsers')
parser = new parsers.RequireJSParser()

readNodes = (source) ->
    script = fs.readFileSync("#{__dirname}/requirejs/#{source}.coffee", 'utf-8')
    return parser.getNodes(script)

objLength = (obj) ->
    return (k for k of obj).length

describe 'RequireJSParser', ->

    describe 'provides a getDependencies method and', ->

        it "parses module = require('module')", ->
            script = """
                     var1 = require('mod1')
                     define ->
                         var2 = require('mod2')
                     require ->
                         var3 = require('mod3')
                     """
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.var1).toBe('mod1')
            expect(deps.var2).toBe('mod2')
            expect(deps.var3).toBe('mod3')
            expect(objLength(deps)).toBe(3)

        it "parses module = require(__dirname + '/module')", ->
            script = """
                     var1 = require(__dirname + '/mod1')
                     define ->
                         var2 = require(__dirname + '/mod2')
                     require ->
                         var3 = require(__dirname + '/mod3')
                     """
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.var1).toBe('./mod1')
            expect(deps.var2).toBe('./mod2')
            expect(deps.var3).toBe('./mod3')
            expect(objLength(deps)).toBe(3)

        it "parses require = {}", ->
            script = "require = {}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: []}", ->
            script = "require = {deps: []}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: ['mod']}", ->
            script = "require = {deps: ['mod']}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod1', 'mod2']}", ->
            script = "require = {deps: ['mod1', 'mod2']}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require = {callback: (->)}", ->
            script = "require = {callback: (->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: [], callback: (->)}", ->
            script = "require = {deps: [], callback: (->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: ['mod'], callback: (->)}", ->
            script = "require = {deps: ['mod'], callback: (->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod1', 'mod2'], callback: (->)}", ->
            script = "require = {deps: ['mod1', 'mod2'], callback: (->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require = {deps: ['mod'], callback: ((arg)->)}", ->
            script = "require = {deps: ['mod'], callback: ((arg)->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod'], callback: (arg)->}", ->
            script = "require = {deps: ['mod'], callback: (arg)->}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod1', 'mod2'], callback: ((arg1)->)}", ->
            script = "require = {deps: ['mod1', 'mod2'], callback: ((arg1)->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require = {deps: ['mod1', 'mod2'], callback: ((arg1, arg2)->)}", ->
            script = "require = {deps: ['mod1', 'mod2'], callback: ((arg1, arg2)->)}"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require((->))", ->
            script = "require((->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require([], (->))", ->
            script = "require([], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require(['mod'], (->))", ->
            script = "require ['mod'], ->"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require(['mod'], ((arg)->))", ->
            script = "require(['mod'], ((arg)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require(['mod1', 'mod2'], (->))", ->
            script = "require(['mod1', 'mod2'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require(['mod1', 'mod2'], ((arg1)->))", ->
            script = "require(['mod1', 'mod2'], ((arg1)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require(['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "require(['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require({}, (->))", ->
            script = "require({}, (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require({}, [], (->))", ->
            script = "require({}, [], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses require({}, ['mod'], (->))", ->
            script = "require({}, ['mod'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require({}, ['mod'], ((arg)->))", ->
            script = "require({}, ['mod'], ((arg)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require({}, ['mod1', 'mod2'], (->))", ->
            script = "require({}, ['mod1', 'mod2'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require({}, ['mod1', 'mod2'], ((arg1)->))", ->
            script = "require({}, ['mod1', 'mod2'], ((arg1)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require({}, ['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "require({}, ['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define((->))", ->
            script = "define((->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses define([], (->))", ->
            script = "define([], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses define(['mod'], (->))", ->
            script = "define(['mod'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define(['mod'], ((arg)->))", ->
            script = "define(['mod'], ((arg)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define(['mod1', 'mod2'], (->))", ->
            script = "define(['mod1', 'mod2'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define(['mod1', 'mod2'], ((arg1)->))", ->
            script = "define(['mod1', 'mod2'], ((arg1)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define(['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "define(['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define('', (->))", ->
            script = "define('', (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses define('', [], (->))", ->
            script = "define('', [], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it "parses define('', ['mod'], (->))", ->
            script = "define('', ['mod'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define('', ['mod'], ((arg)->))", ->
            script = "define('', ['mod'], ((arg)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define('', ['mod1', 'mod2'], (->))", ->
            script = "define('', ['mod1', 'mod2'], (->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define('', ['mod1', 'mod2'], ((arg1)->))", ->
            script = "define('', ['mod1', 'mod2'], ((arg1)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define('', ['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "define('', ['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define ['mod'], (arg) ->", ->
            script = "define ['mod'], (arg) ->"
            nodes = parser.getNodes(script)
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

    describe 'provides a getClasses method and', ->

        it 'handles top-level classes', ->
        it 'handles classes inside of define', ->
        it 'handles classes inside of require', ->

    describe 'provides a getObjects method and', ->

        it 'handles top-level objects', ->
        it 'handles objects inside of define', ->
        it 'handles objects inside of require', ->

    describe 'provides a getFunctions method and', ->

        it 'handles top-level functions', ->
        it 'handles functions inside of define', ->
        it 'handles functions inside of require', ->

