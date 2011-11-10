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
    return [].concat(root_node.expressions, root_node)

exports.getFullName = (variable) ->
    ###
    Given a variable node, returns its full name
    ###
    name = variable.base.value
    if variable.properties.length > 0
        name += '.' + (p.name.value for p in variable.properties).join('.')
    return name

exports.getAttr = (node, path) ->
    ###
    Safe function for looking up paths in the AST. If an attribute is
    undefined at any part of the path, an object with is returned with the
    type attribute set to null
    ###
    path = path.split('.')
    nullObj = {type: null}
    for attr in path
        index = null
        if '[' in attr
            [attr, index] = attr.split('[')
            index = index[..-2]

        node = node[attr]
        if not node?
            return nullObj
        if index?
            node = node[parseInt(index)]
            if not node?
                return nullObj
    return node
