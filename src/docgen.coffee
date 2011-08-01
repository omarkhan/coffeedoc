###
Documentation generator
=======================
This script generates html documentation from a coffeescript source file
###

fs = require('fs')
path = require('path')
eco = require('eco')
showdown = require(__dirname + '/../vendor/showdown').Showdown
coffeedoc = require(__dirname + '/coffeedoc')

renderMarkdown = (obj) ->
    ###
    Helper function that transforms markdown docstring within an AST node
    into html, in place
    ###
    if obj.docstring
        obj.docstring = showdown.makeHtml(obj.docstring)
    return null

# Fetch resources
template = fs.readFileSync(__dirname + '/../resources/coffeedoc.eco', 'utf-8')
css = fs.readFileSync(__dirname + '/../resources/coffeedoc.css', 'utf-8')

# Iterate over source scripts
sources = process.argv[2...process.argv.length]
source_names = (path.basename(s, path.extname(s)) for s in sources)
if sources.length > 0
    # Make docs/ directory under current dir
    fs.mkdir 'docs', '755', ->
        for source, idx in sources
            script = fs.readFileSync(source, 'utf-8')

            # Fetch documentation information
            documentation =
                module_name: path.basename(source)
                module: coffeedoc.documentModule(script)

            # Check for classes inheriting from classes in other modules
            for cls in documentation.module.classes when cls.parent
                clspath = cls.parent.split('.')
                if clspath.length > 1
                    prefix = clspath.shift()
                    if prefix of documentation.module.deps
                        module_path = documentation.module.deps[prefix]
                        module_filename = path.basename(module_path, path.extname(module_path))
                        if module_filename in source_names
                            cls.parent_module = module_filename
                            cls.parent_name = clspath.join('.')

            # Convert markdown to html
            renderMarkdown(documentation.module)
            for c in documentation.module.classes
                renderMarkdown(c)
                renderMarkdown(m) for m in c.methods
            renderMarkdown(f) for f in documentation.module.functions

            # Generate docs
            html = eco.render(template, documentation)

            # Write to file
            fs.writeFile('docs/' + source_names[idx] + '.html', html)

        # Write css stylesheet to docs/resources/
        fs.mkdir 'docs/resources', '755', ->
            fs.writeFile('docs/resources/coffeedoc.css', css)

