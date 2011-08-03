###
Syntax tree parsers
===================

These classes provide provide methods for extracting classes and functions from
the CoffeeScript AST. Each parser class is specific to a module loading system
(e.g.  CommonJS, RequireJS), and should implement the `getDependencies`,
`getClasses` and `getFunctions` methods. Parsers are selected via command line
option.
###

class BaseParser
    ###
    This base class defines the interface for parsers. Subclasses should
    implement these methods.
    ###
    getNodes: (root_node) ->
        ###
        Traverse the AST, adding a 'type' attribute to each node containing the
        name of the node's constructor, and return the expressions array
        ###
        return null

    getDependencies: (nodes) ->
        ###
        Parse require statements and return a hash of module
        dependencies of the form:

            {
                "local.name": "path/to/module"
            }
        ###
        return []
    
    getClasses: (nodes) ->
        ###
        Return an array of class nodes. Be sure to include classes that are
        assigned to variables, e.g. `exports.MyClass = class MyClass`
        ###
        return []

    getFunctions: (nodes) ->
        ###
        Return an array of function nodes.
        ###
        return []


exports.CommonJSParser = class CommonJSParser extends BaseParser
    ###
    Parses code written according to CommonJS specifications:

        require("module")
        exports.func = ->
    ###
    getNodes: (root_node) ->
        root_node.traverseChildren false, (node) ->
            node.type = node.constructor.name
        return root_node.expressions

    getDependencies: (nodes) ->
        ###
        This currently works with the following `require` calls:

            local_name = require("path/to/module")

        or

            local_name = require(__dirname + "/path/to/module")

        In the second example, `__dirname` is replaced with a `.` in the output.
        ###
        stripQuotes = (str) ->
            return str.replace(/('|\")/g, '')

        deps = {}
        for n in nodes when n.type == 'Assign'
            if n.value.type == 'Call' and n.value.variable.base.value == 'require'
                arg = n.value.args[0]
                if arg.type == 'Value'
                    module_path = stripQuotes(arg.base.value)
                else if arg.type == 'Op' and arg.operator == '+'
                    module_path = '.' + stripQuotes(arg.second.base.value)
                else
                    continue
                local_name = getFullName(n.variable)
                deps[local_name] = module_path
        return deps

    getClasses: (nodes) ->
        return (n for n in nodes when n.type == 'Class' \
                or n.type == 'Assign' and n.value.type == 'Class')

    getFunctions: (nodes) ->
        return (n for n in nodes \
                when n.type == 'Assign' and n.value.type == 'Code')


exports.RequireJSParser = class RequireJSParser extends BaseParser
    ###
    Parses code written according to RequireJS specifications:

        require [], ->
            ... code ...

        define [], () ->
            ... code ...
    ###
    getNodes: (root_node) ->
        nodes = []
        moduleLdrs = ['define', 'require']
        root_node.traverseChildren false, (node) ->
            node.type = node.constructor.name
            node.level = 1
            if node.type is 'Call' and node.variable.base.value in moduleLdrs
                for arg in node.args
                    if arg.constructor.name is 'Code'
                        arg.body.traverseChildren false, (node) ->
                            node.type = node.constructor.name
                            node.level = 2
                        nodes = nodes.concat(arg.body.expressions)
                    # TODO: Support objects passed to require or define
            #console.log(node)
        return root_node.expressions.concat(nodes)

    _parseDefine: (node, deps) ->
        # TODO: Support define([..mods..], (..args..) ->)

    _parseRequire: (node, deps) ->
        # TODO: Support require([..mods..], (..args..) ->)

    _parseAssign: (node, deps) ->
        arg = node.value.args[0]
        module_path = @_getModulePath(arg)
        if module_path?
            local_name = @_getFullName(node.variable)
            deps[local_name] = module_path

    _parseObject: (node, deps) ->
        obj = node.value.base
        mods = []
        args = []
        for attr in obj.properties
            if attr.variable.base.value is 'deps' and attr.value.base.type is 'Arr'
                for mod in attr.value.base.objects
                    mod_path = @_getModulePath(mod)
                    if mod_path?
                        mods.push(mod_path)
            else if (attr.variable.base.value is 'callback' \
                     and attr.value.base.body.expressions[0].type is 'Code')
                func = attr.value.base.body.expressions[0]
                for arg in func.params
                    args.push(arg.name.value)

        index = 0
        for mod in mods
            local_name = if index < args.length then args[index] else mod
            deps[local_name] = mod
            index++

    _stripQuotes: (str) ->
        return str.replace(/('|\")/g, '')

    _getModulePath: (mod) ->
        if mod.type is 'Value'
            return @_stripQuotes(mod.base.value)
        else if mod.type is 'Op' and mod.operator is '+'
            return '.' + @_stripQuotes(mod.second.base.value)
        return null

    _getFullName: (variable) ->
        name = variable.base.value
        if variable.properties.length > 0
            name += '.' + (p.name.value for p in variable.properties).join('.')
        return name

    getDependencies: (nodes) ->
        ###
        This currently works with the following `require` calls:

            local_name = require("path/to/module")
            local_name = require(__dirname + "/path/to/module")

        And the following `require` object assignments:

            require = {deps: ["path/to/module"]}
            require = {deps: ["path/to/module"], callback: (module) ->}

        NOTE: require([], ->) and define([], ->) are not yet implemented
        ###
        deps = {}
        for n in nodes
            if n.type is 'Call'
                if n.variable.base.value is 'define'
                    @_parseDefine(n, deps)
                else if n.variable.base.value is 'require'
                    @_parseRequire(n, deps)
            else if n.type is 'Assign'
                if n.value.type is 'Call' and n.value.variable.base.value is 'require'
                    @_parseAssign(n, deps)
                else if (n.level is 1 and n.variable.base.value is 'require' \
                         and n.value.base.type is 'Obj')
                    @_parseObject(n, deps)
        return deps

    getClasses: (nodes) ->
        return (n for n in nodes when n.type == 'Class' \
                or n.type == 'Assign' and n.value.type == 'Class')

    getFunctions: (nodes) ->
        return (n for n in nodes \
                when n.type == 'Assign' and n.value.type == 'Code')
