###
Coffeedoc Cakefile, adapted from [docco](http://jashkenas.github.com/docco/)
by jashkenas
###

exec = require('child_process').exec
path = require('path')

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'install', 'install the `coffeedoc` command into /usr/local (or --prefix)', (options) ->
    base = options.prefix or '/usr/local'
    lib = path.join(base, 'lib/coffeedoc')
    exec([
        'mkdir -p ' + lib
        'cp -rf bin README.md resources src ' + lib
        "ln -sf #{path.join(lib, 'bin/coffeedoc')} #{path.join(base, 'bin/coffeedoc')}"
    ].join(' && '), (err, stdout, stderr) ->
        if err
            process.stderr.write(stderr)
    )

task 'test', 'run unit tests', (options) ->
    exec('jasmine-node --coffee spec', (err, stdout, stderr) ->
        if err
            process.stderr.write(stderr)
        else
            process.stdout.write(stdout)
    )
