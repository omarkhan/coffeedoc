parsers = require(__dirname + '/../src/parsers')
coffeedoc = require(__dirname + '/../src/coffeedoc')
helpers = require(__dirname + '/../src/helpers')
parser = new parsers.requirejs()

parseNodes = (script) ->
    return coffeedoc.documentModule(script, parser)

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
            nodes = parseNodes(script)
            deps = nodes.deps
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
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.var1).toBe('./mod1')
            expect(deps.var2).toBe('./mod2')
            expect(deps.var3).toBe('./mod3')
            expect(objLength(deps)).toBe(3)

        it "parses require = {}", ->
            script = "require = {}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: []}", ->
            script = "require = {deps: []}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: ['mod']}", ->
            script = "require = {deps: ['mod']}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod1', 'mod2']}", ->
            script = "require = {deps: ['mod1', 'mod2']}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require = {callback: (->)}", ->
            script = "require = {callback: (->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: [], callback: (->)}", ->
            script = "require = {deps: [], callback: (->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require = {deps: ['mod'], callback: (->)}", ->
            script = "require = {deps: ['mod'], callback: (->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod1', 'mod2'], callback: (->)}", ->
            script = "require = {deps: ['mod1', 'mod2'], callback: (->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require = {deps: ['mod'], callback: ((arg)->)}", ->
            script = "require = {deps: ['mod'], callback: ((arg)->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod'], callback: (arg)->}", ->
            script = "require = {deps: ['mod'], callback: (arg)->}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require = {deps: ['mod1', 'mod2'], callback: ((arg1)->)}", ->
            script = "require = {deps: ['mod1', 'mod2'], callback: ((arg1)->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require = {deps: ['mod1', 'mod2'], callback: ((arg1, arg2)->)}", ->
            script = "require = {deps: ['mod1', 'mod2'], callback: ((arg1, arg2)->)}"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require((->))", ->
            script = "require((->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require([], (->))", ->
            script = "require([], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require(['mod'], (->))", ->
            script = "require ['mod'], ->"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require(['mod'], ((arg)->))", ->
            script = "require(['mod'], ((arg)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require(['mod1', 'mod2'], (->))", ->
            script = "require(['mod1', 'mod2'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require(['mod1', 'mod2'], ((arg1)->))", ->
            script = "require(['mod1', 'mod2'], ((arg1)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require(['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "require(['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require({}, (->))", ->
            script = "require({}, (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require({}, [], (->))", ->
            script = "require({}, [], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses require({}, ['mod'], (->))", ->
            script = "require({}, ['mod'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require({}, ['mod'], ((arg)->))", ->
            script = "require({}, ['mod'], ((arg)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses require({}, ['mod1', 'mod2'], (->))", ->
            script = "require({}, ['mod1', 'mod2'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require({}, ['mod1', 'mod2'], ((arg1)->))", ->
            script = "require({}, ['mod1', 'mod2'], ((arg1)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses require({}, ['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "require({}, ['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define((->))", ->
            script = "define((->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses define([], (->))", ->
            script = "define([], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses define(['mod'], (->))", ->
            script = "define(['mod'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define(['mod'], ((arg)->))", ->
            script = "define(['mod'], ((arg)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define(['mod1', 'mod2'], (->))", ->
            script = "define(['mod1', 'mod2'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define(['mod1', 'mod2'], ((arg1)->))", ->
            script = "define(['mod1', 'mod2'], ((arg1)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define(['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "define(['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define('', (->))", ->
            script = "define('', (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses define('', [], (->))", ->
            script = "define('', [], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(objLength(deps)).toBe(0)

        it "parses define('', ['mod'], (->))", ->
            script = "define('', ['mod'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define('', ['mod'], ((arg)->))", ->
            script = "define('', ['mod'], ((arg)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it "parses define('', ['mod1', 'mod2'], (->))", ->
            script = "define('', ['mod1', 'mod2'], (->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define('', ['mod1', 'mod2'], ((arg1)->))", ->
            script = "define('', ['mod1', 'mod2'], ((arg1)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define('', ['mod1', 'mod2'], ((arg1, arg2)->))", ->
            script = "define('', ['mod1', 'mod2'], ((arg1, arg2)->))"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it "parses define ['mod'], (arg) ->", ->
            script = "define ['mod'], (arg) ->"
            nodes = parseNodes(script)
            deps = nodes.deps
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

    describe 'provides a getClasses method and', ->

        it 'handles top-level classes', ->
            script = """
                     class Test
                         constructor: ->
                         method1: ->
                         method2: ->
                     """
            nodes = parseNodes(script)
            classes = nodes.classes
            expect(classes.length).toBe(1)
            expect(classes[0].name).toBe('Test')

        it 'handles classes inside of define', ->
            script = """
                     define ['mod'], (arg) ->
                         class Test
                             constructor: ->
                             method1: ->
                             method2: ->
                     """
            nodes = parseNodes(script)
            classes = nodes.classes
            expect(classes.length).toBe(1)
            expect(classes[0].name).toBe('Test')

        it 'handles classes inside of require', ->
            script = """
                     require ['mod'], (arg) ->
                         class Test
                             constructor: ->
                             method1: ->
                             method2: ->
                     """
            nodes = parseNodes(script)
            classes = nodes.classes
            expect(classes.length).toBe(1)
            expect(classes[0].name).toBe('Test')

    describe 'provides a getObjects method and', ->

        it 'handles top-level objects', ->
            script = """
                     test1 =
                         val: true

                     test2 = {val: false}
                     """
            nodes = parser.getNodes(script)
            objs = parser.getObjects(nodes)
            expect(objs.length).toBe(2)
            expect(objs[0].variable.base.value).toBe('test1')
            expect(objs[1].variable.base.value).toBe('test2')

        it 'handles objects inside of define', ->
            script = """
                     define ['mod'], (arg) ->
                         test1 =
                             val: true

                         test2 = {val: false}
                     """
            nodes = parser.getNodes(script)
            objs = parser.getObjects(nodes)
            expect(objs.length).toBe(2)
            expect(objs[0].variable.base.value).toBe('test1')
            expect(objs[1].variable.base.value).toBe('test2')

        it 'handles objects inside of require', ->
            script = """
                     require ['mod'], (arg) ->
                         test1 =
                             val: true

                         test2 = {val: false}
                     """
            nodes = parser.getNodes(script)
            objs = parser.getObjects(nodes)
            expect(objs.length).toBe(2)
            expect(objs[0].variable.base.value).toBe('test1')
            expect(objs[1].variable.base.value).toBe('test2')

    describe 'provides a getFunctions method and', ->

        it 'handles top-level functions', ->
            script = "test = ->"
            nodes = parseNodes(script)
            funcs = nodes.functions
            expect(funcs.length).toBe(1)
            expect(funcs[0].name).toBe('test')

        it 'handles functions inside of define', ->
            script = """
                     define ['mod'], (arg) ->
                         test = ->
                     """
            nodes = parseNodes(script)
            funcs = nodes.functions
            expect(funcs.length).toBe(1)
            expect(funcs[0].name).toBe('test')

        it 'handles functions inside of require', ->
            script = """
                     require ['mod'], (arg) ->
                         test = ->
                     """
            nodes = parseNodes(script)
            funcs = nodes.functions
            expect(funcs.length).toBe(1)
            expect(funcs[0].name).toBe('test')

    describe 'parse classes and', ->

        it 'place private methods to private sections', ->
            script = """
                     class Test
                         constructor: ->
                         method1: ->
                         method2: ->
                         _method3: ->
                         __method4: ->
                     """
            nodes = parseNodes(script)
            my_class = nodes.classes[0]
            expect(my_class.instancemethods.length).toBe(3)
            expect(my_class.privatemethods.length).toBe(2)
