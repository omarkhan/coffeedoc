###
Coffeedoc Cakefile, adapted from [docco](http://jashkenas.github.com/docco/)
by jashkenas
###

{spawn, exec} = require 'child_process'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'build', 'continually build the coffeedoc library with --watch', ->
  coffee = spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> console.log data.toString().trim()

task 'install', 'install the `coffeedoc` command into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib = base + '/lib/coffeedoc'
  exec([
    'mkdir -p ' + lib
    'cp -rf bin README.md resources lib ' + lib
    'ln -sf ' + lib + '/bin/coffeedoc ' + base + '/bin/coffeedoc'
  ].join(' && '), (err, stdout, stderr) ->
   if err then console.error stderr
  )
