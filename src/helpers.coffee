###
AST helper functions
====================

Useful functions for dealing with the CoffeeScript parse tree.
###

exports.getFullName = (variable) ->
    ###
    Given a variable node, returns its full name
    ###
    name = variable.base.value
    if variable.properties.length > 0
        name += '.' + (p.name.value for p in variable.properties).join('.')
    return name

