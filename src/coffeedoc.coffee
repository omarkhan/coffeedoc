###
Documentation functions
=======================
These functions extract relevant documentation info from AST nodes as returned
by the coffeescript parser.
###

coffeescript = require('coffee-script')

exports.documentModule = (script) ->
    ###
    Given a module's source code, returns module information in the form:

        {
            "docstring": "Module docstring",
            "classes": [class1, class1...],
            "functions": [func1, func2...]
        }
    ###
    nodes = getNodes(script)
    first_obj = nodes[0]
    if first_obj?.type == 'Comment'
        docstring = removeLeadingWhitespace(first_obj.comment)
    else
        docstring = null
    
    doc =
        docstring: docstring
        classes: (documentClass(c) for c in getClasses(nodes))
        functions: (documentFunction(f) for f in getFunctions(nodes))

    return doc

getNodes = (script) ->
    ###
    Generates the AST from coffeescript source code.  Adds a 'type' attribute
    to each node containing the name of the node's constructor, and returns
    the expressions array
    ###
    root_node = coffeescript.nodes(script)
    root_node.traverseChildren false, (node) ->
        node.type = node.constructor.name
    return root_node.expressions

getClasses = (nodes) ->
    ###
    Returns all top-level class nodes from the AST as returned by getNodes
    ###
    return (n for n in nodes when n.type == 'Class' \
            or n.type == 'Assign' and n.value.type == 'Class')

getFunctions = (nodes) ->
    ###
    Returns all top-level named function nodes from the AST as returned by
    getNodes
    ###
    return (n for n in nodes \
            when n.type == 'Assign' and n.value.type == 'Code')

getNodeName = (node) ->
    ###
    Given a node, returns its full name
    ###
    name = node.variable.base.value
    properties = node.variable.properties
    if properties.length > 0
        name += '.' + (prop.name.value for prop in properties).join('.')
    return name

documentClass = (cls) ->
    ###
    Evaluates a class object as returned by the coffeescript parser, returning
    an object of the form:
    
        {
            "name": "MyClass",
            "docstring": "First comment following the class definition"
            "parent": "MySuperClass",
            "methods": [method1, method2...]
        }
    ###
    if cls.type == 'Assign'
        # Class assigned to variable -- ignore the variable definition
        cls = cls.value

    # Get docstring
    first_obj = cls.body.expressions[0].base.objects[0]
    if first_obj?.type == 'Comment'
        docstring = removeLeadingWhitespace(first_obj.comment)
    else
        docstring = null

    # Get methods
    methods = (n for n in cls.body.expressions[0].base.objects \
               when n.type == 'Assign' and n.value.type == 'Code')

    doc =
        name: getNodeName(cls)
        docstring: docstring
        parent: cls.parent?.base.value or null
        methods: (documentFunction(m) for m in methods)

    return doc

documentFunction = (func) ->
    ###
    Evaluates a function object as returned by the coffeescript parser,
    returning an object of the form:
    
        {
            "name": "myFunc",
            "docstring": "First comment following the function definition",
            "params": ["param1", "param2"...]
        }
    ###
    # Get docstring
    first_obj = func.value.body.expressions[0]
    if first_obj?.comment
        docstring = removeLeadingWhitespace(first_obj.comment)
    else
        docstring = null

    # Get params
    if func.value.params
        params = for p in func.value.params
            if p.splat then p.name.value + '...' else p.name.value
    else
        params = []

    doc =
        name: getNodeName(func)
        docstring: docstring
        params: params

removeLeadingWhitespace = (str) ->
    ###
    Given a string, returns it with leading whitespace removed but with
    indentation preserved
    ###
    lines = str.split('\n')

    # Remove leading blank lines
    while /^ *$/.test(lines[0])
        lines.shift()
    if lines.length == 0
        return null

    # Get least indented non-blank line
    indentation = for line in lines
        if /^ *$/.test(line) then continue
        line.match(/^ */)[0].length
    indentation = Math.min(indentation...)

    leading_whitespace = new RegExp("^ {#{ indentation }}")
    return (line.replace(leading_whitespace, '') for line in lines).join('\n')

