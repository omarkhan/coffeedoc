###
AST helper functions
====================

Useful functions for dealing with the CoffeeScript parse tree.
###

coffeescript = require('coffee-script')

exports.getNodes = (script) ->
    ###
    Generates the AST from coffeescript source code.  Adds a 'type' attribute
    to each node containing the name of the node's constructor, and returns
    the expressions array
    ###
    root_node = coffeescript.nodes(script)
    root_node.traverseChildren false, (node) ->
        node.type = node.constructor.name
    return root_node.expressions

exports.getFullName = (variable) ->
    ###
    Given a variable node, returns its full name
    ###
    name = variable.base.value
    if variable.properties.length > 0
        name += '.' + (p.name.value for p in variable.properties).join('.')
    return name

