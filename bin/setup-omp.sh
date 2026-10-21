#!/usr/bin/env bash
# combine-assistant on omp (oh-my-pi, https://omp.sh): the counterpart of
# bin/setup.sh (opencode). Source it:
#   source <combine-assistant>/bin/setup-omp.sh
#
# Builds a per-user omp agent dir (default /tmp/$USER-combine-assistant-omp/agent):
#   config/omp/{models.yml,mcp.json,config.yml}  omp provider, MCP servers, permissions
#   config/AGENTS.md, config/skills/             the same persona and skill as opencode
# If this tree has no config/AGENTS.md (standalone omp overlay), they are taken from
# COMBINE_ASSISTANT_SRC (default: the CVMFS release).
#
# Knobs:
#   COMBINE_ASSISTANT_OMP_HOME   per-user writable base (default /tmp/$USER-combine-assistant-omp)
#   COMBINE_ASSISTANT_SRC        combine-assistant tree for AGENTS.md/skills
#   COMBINE_ASSISTANT_NO_WEB=1   disable omp's built-in fetch and web_search tools
#   OMP_BIN_DIR                  dir containing the omp binary, if not on PATH

_cao_src="${BASH_SOURCE[0]:-$0}"
_cao_root="$(cd -P "$(dirname "$_cao_src")/.." >/dev/null 2>&1 && pwd)"
_cao_home="${COMBINE_ASSISTANT_OMP_HOME:-/tmp/${USER:-$(id -un)}-combine-assistant-omp}"
_cao_agent="$_cao_home/agent"
if [ -r "$_cao_root/config/AGENTS.md" ]; then
  _cao_persona="$_cao_root/config"
else
  _cao_persona="${COMBINE_ASSISTANT_SRC:-/cvmfs/cms-griddata.cern.ch/cat/sw/combine-assistant/latest}/config"
fi

rm -rf "$_cao_agent"
mkdir -p "$_cao_agent/skills"
cp -a "$_cao_root/config/omp/." "$_cao_agent/"
cp -a "$_cao_persona/AGENTS.md" "$_cao_agent/AGENTS.md"
cp -a "$_cao_persona/skills/." "$_cao_agent/skills/"
if [ "${COMBINE_ASSISTANT_NO_WEB:-0}" = "1" ]; then
  printf '\n# COMBINE_ASSISTANT_NO_WEB=1: answers must come from the combine MCP sources\nfetch:\n  enabled: false\nweb_search:\n  enabled: false\n' >> "$_cao_agent/config.yml"
fi

export PI_CODING_AGENT_DIR="$_cao_agent"
export PI_NO_TITLE=1
if [ -n "${OMP_BIN_DIR:-}" ]; then
  case ":$PATH:" in *":$OMP_BIN_DIR:"*) ;; *) export PATH="$OMP_BIN_DIR:$PATH" ;; esac
fi
export COMBINE_ASSISTANT_VERSION="$(cat "$_cao_root/VERSION" 2>/dev/null || echo omp-overlay)"

echo "combine-assistant (omp) ready: $(omp --version 2>/dev/null || echo 'omp NOT on PATH')"
echo "  PI_CODING_AGENT_DIR=$PI_CODING_AGENT_DIR (persona/skill from $_cao_persona)"
[ "${COMBINE_ASSISTANT_NO_WEB:-0}" = "1" ] && echo "  web fetch/search disabled"
[ -n "${AIGW_API_KEY:-}" ] || echo "  AIGW_API_KEY is not set (see bin/setup.sh for how to get one)" >&2
unset _cao_src _cao_root _cao_home _cao_agent _cao_persona
