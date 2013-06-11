###
Documentation functions
=======================

These functions extract relevant documentation info from AST nodes as returned
by the coffeescript parser.
###

getFullName = require(__dirname + '/helpers').getFullName


documentModule = (script, parser) ->
    ###
    Given a module's source code and an AST parser, returns module information
    in the form:

        {
            "docstring": "Module docstring",
            "classes": [class1, class1...],
            "functions": [func1, func2...]
        }

    AST parsers are defined in the `parsers.coffee` module
    ###
    nodes = parser.getNodes(script)
    first_obj = nodes[0]
    if first_obj?.type == 'Comment'
        docstring = formatDocstring(first_obj.comment)
    else
        docstring = null

    allFunctions = parser.getFunctions(nodes)
    doc = {
        docstring: docstring
        deps: parser.getDependencies(nodes)
        classes: (documentClass(c) for c in parser.getClasses(nodes))
        functions: (documentFunction(f) for f in allFunctions when not _isPrivateFunction(f))
        privateFunctions: (documentFunction(f) for f in allFunctions when _isPrivateFunction(f))
    }

    return doc


documentClass = (cls) ->
    ###
    Evaluates a class object as returned by the coffeescript parser, returning
    an object of the form:

        {
            "name": "MyClass",
            "docstring": "First comment following the class definition"
            "parent": "MySuperClass",
            "methods": [method1, method2...],
            "lineno": 123
        }
    ###
    if cls.type == 'Assign'
        # Class assigned to variable -- ignore the variable definition
        cls = cls.value

    expressions = cls.body.expressions
    firstObj = expressions[0]

    # Classes that do not inherit from other classes seem to end up with a
    # different representation in the AST
    if firstObj?.base?.type == 'Obj'
        firstObj = firstObj.base.objects[0]

    # Get docstring
    if firstObj?.type == 'Comment'
        docstring = formatDocstring(firstObj.comment)
    else
        docstring = null

    # Get methods
    staticmethods = []
    instancemethods = []
    privatemethods = []
    for expr in expressions
        if expr.type == 'Value' and expr.base.objects
            for method in (n for n in expr.base.objects \
                           when n.type == 'Assign' and n.value.type == 'Code')
                if method.variable.this
                    # Method attached to `this`, i.e. the constructor
                    staticmethods.push(method)
                else
                    # Method attached to prototype
                    if method.variable.base.value?.match /^_/
                        privatemethods.push(method)
                    else
                        instancemethods.push(method)
        else if expr.type == 'Assign' and expr.value.type == 'Code'
            # Static method
            if expr.variable.this # Only include public methods
                staticmethods.push(expr)

    if cls.parent?
        parent = getFullName(cls.parent)
    else
        parent = null

    doc = {
        name: getFullName(cls.variable)
        lineno: cls.variable.locationData.first_line
        docstring: docstring
        parent: parent
        staticmethods: (documentFunction(m) for m in staticmethods)
        instancemethods: (documentFunction(m) for m in instancemethods)
        privatemethods: (documentFunction(m) for m in privatemethods)
    }

    for method in doc.staticmethods
        method.name = method.name.replace(/^this\./, '')

    return doc


documentFunction = (func) ->
    ###
    Evaluates a function object as returned by the coffeescript parser,
    returning an object of the form:

        {
            "name": "myFunc",
            "docstring": "First comment following the function definition",
            "params": ["param1", "param2"...],
            "lineno": 123
        }
    ###
    # Get docstring
    first_obj = func.value.body.expressions[0]
    if first_obj?.comment
        docstring = formatDocstring(first_obj.comment)
    else
        docstring = null

    # Get params
    if func.value.params
        params = for p in func.value.params
            if p.name.base?.value == 'this'
                '@' + p.name.properties[0].name.value
            else
                if p.splat then p.name.value + '...' else p.name.value

    else
        params = []

    doc = {
        name: getFullName(func.variable)
        lineno: func.variable.locationData.first_line
        docstring: docstring
        params: params
    }


formatDocstring = (str) ->
    ###
    Given a string, returns it with leading whitespace removed but with
    indentation preserved. Replaces `\\#` with `#` to allow for the use of
    multiple `#` characters in markup languages (e.g. Markdown headers)
    ###
    lines = str.replace(/\\#/g, '#').split('\n')

    # Remove leading blank lines
    while /^\s*$/.test(lines[0])
        lines.shift()
    if lines.length == 0
        return null

    # Get least indented non-blank line
    indentation = for line in lines
        if /^\s*$/.test(line) then continue
        line.match(/^\s*/)[0].length
    indentation = Math.min(indentation...)

    leading_whitespace = new RegExp("^\\s{#{ indentation }}")
    return (line.replace(leading_whitespace, '') for line in lines).join('\n')


_isPrivateFunction = (func) -> func.variable.base.value.match /^_/

exports.documentModule = documentModule
