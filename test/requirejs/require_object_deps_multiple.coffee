require = {deps: [mod1, mod2]}
                     
# XXX: THESE SHOULD NOT BE PICKED UP                     
define ->
    require = {deps: [mod3, mod4]}

require ->
    require = {deps: [mod5, mod6]}
