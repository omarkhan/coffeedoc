###
# Single class inside a define() call #
###

define ['mod1', __dirname + '/mod2'], (mod1, mod2) ->

    class Test
        ### Documentation for Test ###

        constructor: ->
            ### constructor documentation ###

        method1: ->
            ### method1 documentation ###

        method2: ->
            ### method2 documentation ###
