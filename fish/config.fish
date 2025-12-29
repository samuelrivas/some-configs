if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx EDITOR emacs -nw

# some fish upgrade changed thsi to backwared-kill-token, which confuses me all
# the time
bind alt-backspace backward-kill-word
