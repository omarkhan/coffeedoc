###
Syntax tree parsers
===================

These classes provide provide methods for extracting classes and functions from
the CoffeeScript AST. Each parser class is specific to a module loading system
(e.g.  CommonJS, RequireJS), and should implement the `getDependencies`,
`getClasses` and `getFunctions` methods. Parsers are selected via command line
option.
###

helpers = require(__dirname + '/helpers')

class BaseParser
    ###
    This base class defines the interface for parsers. Subclasses should
    implement these methods.
    ###
    getDependencies: (nodes) ->
        ###
        Parse require statements and return a hash of module
        dependencies of the form:

            {
                "local.name": "path/to/module"
            }
        ###
        return {}
    
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
    getDependencies: (nodes) ->
        ###
        This currently works with the following `require` calls:

            local_name = require("path/to/module")

        or

            local_name = require(__dirname + "/path/to/module")
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
                    module_path = stripQuotes(arg.second.base.value).replace(/^\//, '')
                else
                    continue
                local_name = helpers.getFullName(n.variable)
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
    Not yet implemented
    ###
