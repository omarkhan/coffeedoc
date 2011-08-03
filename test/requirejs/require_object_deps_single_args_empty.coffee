require = {deps: [mod], callback: (->)}
                     
# XXX: THESE SHOULD NOT BE PICKED UP                     
define ->
    require = {deps: [mod1], callback: (->)}

require ->
    require = {deps: [mod2], callback: (->)}
