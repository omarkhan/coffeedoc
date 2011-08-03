require = {deps: [mod1, mod2], callback: (->)}
                     
# XXX: THESE SHOULD NOT BE PICKED UP                     
define ->
    require = {deps: [mod3, mod4], callback: (->)}

require ->
    require = {deps: [mod5, mod6], callback: (->)}
