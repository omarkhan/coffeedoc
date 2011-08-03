require = {deps: [mod1, mod2], callback: ((arg1, arg2)->)}

# XXX: THESE SHOULD NOT BE PICKED UP                     
define ->
    require = {deps: [mod3, mod4], callback: ((arg3, arg4)->)}

require ->
    require = {deps: [mod5, mod6], callback: ((arg5, arg6)->)}
