require = {deps: [mod], callback: ((arg)->)}
                     
# XXX: THESE SHOULD NOT BE PICKED UP                     
define ->
    require = {deps: [mod1], callback: ((arg1)->)}

require ->
    require = {deps: [mod2], callback: ((arg2)->)}
