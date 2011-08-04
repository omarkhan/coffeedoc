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
            nodes = readNodes('require_assign_module')
            deps = parser.getDependencies(nodes)
            expect(deps.var1).toBe('mod1')
            expect(deps.var2).toBe('mod2')
            expect(deps.var3).toBe('mod3')
            expect(objLength(deps)).toBe(3)

        it "parses module = require(__dirname + 'module')", ->
            nodes = readNodes('require_assign_dirname_module')
            deps = parser.getDependencies(nodes)
            expect(deps.var1).toBe('./mod1')
            expect(deps.var2).toBe('./mod2')
            expect(deps.var3).toBe('./mod3')
            expect(objLength(deps)).toBe(3)

        it 'parses require = {}', ->
            nodes = readNodes('require_object_empty')
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it 'parses require = {deps: []}', ->
            nodes = readNodes('require_object_deps_empty')
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it 'parses require = {deps: [mod]}', ->
            nodes = readNodes('require_object_deps_single')
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it 'parses require = {deps: [mod1, mod2]}', ->
            nodes = readNodes('require_object_deps_multiple')
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it 'parses require = {callback: (->)}', ->
            nodes = readNodes('require_object_args_empty')
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it 'parses require = {deps: [], callback: (->)}', ->
            nodes = readNodes('require_object_deps_empty_args_empty')
            deps = parser.getDependencies(nodes)
            expect(objLength(deps)).toBe(0)

        it 'parses require = {deps: [mod], callback: (->)}', ->
            nodes = readNodes('require_object_deps_single_args_empty')
            deps = parser.getDependencies(nodes)
            expect(deps.mod).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it 'parses require = {deps: [mod1, mod2], callback: (->)}', ->
            nodes = readNodes('require_object_deps_multiple_args_empty')
            deps = parser.getDependencies(nodes)
            expect(deps.mod1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it 'parses require = {deps: [mod], callback: ((arg)->)}', ->
            nodes = readNodes('require_object_deps_single_args_single')
            deps = parser.getDependencies(nodes)
            expect(deps.arg).toBe('mod')
            expect(objLength(deps)).toBe(1)

        it 'parses require = {deps: [mod1, mod2], callback: ((arg1)->)}', ->
            nodes = readNodes('require_object_deps_multiple_args_single')
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.mod2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it 'parses require = {deps: [mod1, mod2], callback: ((arg1, arg2)->)}', ->
            nodes = readNodes('require_object_deps_multiple_args_multiple')
            deps = parser.getDependencies(nodes)
            expect(deps.arg1).toBe('mod1')
            expect(deps.arg2).toBe('mod2')
            expect(objLength(deps)).toBe(2)

        it 'parses require((->))', ->
        it 'parses require([], (->))', ->
        it 'parses require([mod], (->))', ->
        it 'parses require([mod], ((mod)->))', ->
        it 'parses require([mod1, mod2], (->))', ->
        it 'parses require([mod1, mod2], ((mod1)->))', ->
        it 'parses require([mod1, mod2], ((mod1, mod2)->))', ->
        it 'parses require({})', ->
        it 'parses require({}, (->))', ->
        it 'parses require({}, [])', ->
        it 'parses require({}, [], (->))', ->
        it 'parses require({}, [mod])', ->
        it 'parses require({}, [mod], (->))', ->
        it 'parses require({}, [mod], ((mod)->))', ->
        it 'parses require({}, [mod1, mod2])', ->
        it 'parses require({}, [mod1, mod2], (->))', ->
        it 'parses require({}, [mod1, mod2], ((mod1)->))', ->
        it 'parses require({}, [mod1, mod2], ((mod1, mod2)->))', ->
        it 'parses define({})', ->
        it 'parses define((->))', ->
        it 'parses define(((arg)->))', ->
        it 'parses define([], (->))', ->
        it 'parses define([mod], (->))', ->
        it 'parses define([mod], ((mod)->))', ->
        it 'parses define([mod1, mod2], (->))', ->
        it 'parses define([mod1, mod2], ((mod1)->))', ->
        it 'parses define([mod1, mod2], ((mod1, mod2)->))', ->
        it "parses define('', (->))", ->
        it "parses define('', [], (->))", ->
        it "parses define('', [mod], (->))", ->
        it "parses define('', [mod], ((mod)->))", ->
        it "parses define('', [mod1, mod2], (->))", ->
        it "parses define('', [mod1, mod2], ((mod1)->))", ->
        it "parses define('', [mod1, mod2], ((mod1, mod2)->))", ->

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

