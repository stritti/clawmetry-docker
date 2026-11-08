---
layout: home

hero:
  name: clawmetry-docker
  text: Real-time observability for your AI agents
  tagline: A ready-to-use Docker image for the <a href="https://clawmetry.com/" target="_blank">ClawMetry</a> dashboard — watches 32 agent runtimes (OpenClaw, Claude Code, Codex &amp; more), zero Python setup required.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: clawmetry.com
      link: https://clawmetry.com/
    - theme: alt
      text: Docker Hub
      link: https://hub.docker.com/r/stritti/clawmetry
    - theme: alt
      text: ⭐ Star on GitHub
      link: https://github.com/stritti/clawmetry-docker

features:
  - title: One-command start
    details: Pull and run the pre-built image from Docker Hub — no local Python environment needed. Powered by <a href="https://clawmetry.com/" target="_blank">ClawMetry</a>.
  - title: 32 agent runtimes
    details: Mount the home directory of whichever runtimes you use (OpenClaw, Claude Code, Codex, Gemini CLI, …) — ClawMetry auto-detects them, read-only.
    link: /guide/getting-started
    linkText: Getting started guide
  - title: Automatic updates
    details: A scheduled GitHub Actions workflow checks PyPI daily and publishes a fresh image for every new <a href="https://clawmetry.com/" target="_blank">ClawMetry</a> release.
  - title: Flexible configuration
    details: All settings are configurable via environment variables or CLI flags so you can adapt the container to any workspace layout.
    link: /guide/configuration
    linkText: Configuration reference
---

<div style="text-align:center;margin-top:1.5rem;">
  <a href="https://github.com/stritti/clawmetry-docker" target="_blank">
    <img src="https://img.shields.io/github/stars/stritti/clawmetry-docker?style=social" alt="GitHub Stars">
  </a>
  &nbsp;
  <a href="https://pypi.org/project/clawmetry/" target="_blank">
    <img src="https://img.shields.io/pypi/v/clawmetry?label=ClawMetry" alt="ClawMetry version">
  </a>
  &nbsp;
  <a href="https://hub.docker.com/r/stritti/clawmetry" target="_blank">
    <img src="https://img.shields.io/docker/pulls/stritti/clawmetry?label=Docker%20Pulls" alt="Docker Pulls">
  </a>
</div>
