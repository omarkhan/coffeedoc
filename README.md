CoffeeDoc
=========

An API documentation generator for CoffeeScript
-----------------------------------------------

CoffeeDoc is a simple API documentation generator for [CoffeeScript][]. It reads python-style docstrings in your CoffeeScript class and function definitions, passes them through [Markdown](http://daringfireball.net/projects/markdown/syntax), and outputs the result as easy to read HTML.

The docstring convention CoffeeDoc uses is inspired by Python, and looks like this:

```CoffeeScript
class MyClass extends Superclass
    ###
    This docstring documents MyClass. It can include *Markdown* syntax,
    which will be converted to html.
    ###
    constructor: (@args) ->
        ### Constructor documentation goes here. ###

    method: (args) ->
        ### This is a method of MyClass ###

myFunc = (arg1, arg2, args...) ->
    ###
    This function will be documented by CoffeeDoc
    ###
    doSomething()
```

CoffeeDoc is inspired by the excellent [Docco][], and is intended for projects that require more structured API documentation.

### Installation ###

CoffeeDoc requires [Node.js][], [CoffeeScript][], and [eco][]. Install using npm with the following command:

    sudo npm install -g coffeedoc

The -g option installs CoffeeDoc globally, adding the coffeedoc executable to your PATH. If you would rather install locally, omit the -g option.

You can also install from source using cake. From the source directory, run:

    sudo cake install

### Usage ###

CoffeeDoc can be run from the command line:

    coffeedoc src/*.coffee

Generated documentation is saved to the `docs/` folder under the current directory.

### How it works ###

CoffeeDoc uses the CoffeeScript parser to generate a parse tree for the given source files. It then extracts the relevant information from the parse tree: class and function names, class member functions, function argument lists and docstrings.

Docstrings are defined as the first herecomment block following the class or function definition. Note that regular single line comments will be ignored. Docstrings are passed through [Showdown][], a javascript port of Markdown (CoffeeDoc uses jashkenas' modified version of Showdown used in Docco).

The resulting documentation information is then passed to an [eco][] template to generate the html output.

### Licence ###

CoffeeDoc is © 2011 Omar Khan, released under the MIT licence. Use it, fork it.

[CoffeeScript]: http://jashkenas.github.com/coffee-script/
[Docco]: http://jashkenas.github.com/docco/
[Node.js]: http://nodejs.org/
[eco]: https://github.com/sstephenson/eco
[Showdown]: http://softwaremaniacs.org/playground/showdown-highlight/
