# Sourced by startplasma before it hands its environment to systemd and to every app:
# replace the agent Xsession started (random /tmp socket) with ssh-agent-socket.service's,
# or Plasma would push the Xsession one over environment.d's value.
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
	unset SSH_AGENT_PID
fi
