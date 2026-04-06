# uv adds this file at install time — guard so fish doesn't crash on machines without uv
if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end
