require = {deps: [mod]}
                     
# XXX: THESE SHOULD NOT BE PICKED UP                     
define ->
    require = {deps: [mod1]}

require ->
    require = {deps: [mod2]}
