###
Syntax tree parsers
===================

These classes provide provide methods for extracting classes and functions from
the CoffeeScript AST. Each class is specific to a module loading system (e.g.
CommonJS, RequireJS), and should implement the `getClasses` and `getFunctions`
methods. These methods return an array of class nodes and function nodes
respectively. Parsers are selected via command line option.
###

exports.CommonJSParser = class CommonJSParser
    ###
    Parses code written according to CommonJS specifications:

        require("module")
        exports.func = ->
    ###
    getClasses: (nodes) ->
        return (n for n in nodes when n.type == 'Class' \
                or n.type == 'Assign' and n.value.type == 'Class')

    getFunctions: (nodes) ->
        return (n for n in nodes \
                when n.type == 'Assign' and n.value.type == 'Code')


exports.RequireJSParser = class RequireJSParser
    ###
    Not yet implemented
    ###
    getClasses: (nodes) ->
        throw 'RequireJS parser not yet implemented'

    getFunctions: (nodes) ->
        throw 'RequireJS parser not yet implemented'
