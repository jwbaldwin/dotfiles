# SETUP

This is a document of my current and desired dev setup across all my devices and environments (work/personal), as well as the considerations and constraints that go into my decisions.

## Contents

1. [Considerations](#considerations)
2. [Nice to have](#nice-to-have)
3. [My dev setup](#my-dev-setup)
4. [Workflows](#workflows)
   - [Rex](#rex)
   - [T3Code](#t3code)
   - [Monocode](#monocode)
5. [My ideal setup](#my-ideal-setup)

---

## Considerations

### Always on

- I must have an always-on device
  - My laptop closes, and I want a place to run one-off software, my custom agent (for now), and to keep my agents working even when my laptop is closed.

### Access and connectivity

- I want to be able to work on anything that's on any of my servers from my laptop OR my phone
- They should be always connected
- All through Tailscale
- I can pick up work and continue it on any of my clients

### UX

- Whatever I'm doing must have an iOS app to let me interface with it, and it must be really nice
- Performance and UX is unbelievably crucial
- The design of a GUI should be thoughtful, careful, and considered. Aesthetics matter to me.

### Agents

- I need to be able to use any agents with subscriptions that I want
  - I have a Claude and Codex sub

---

## Nice to have

- Some version of a long-lived thread that can remember its purpose and work across many sessions, spawning them and managing them on my behalf to accomplish the higher-level goal. An ADE must expose these capabilities (e.g. a cli for spawning threads and reviewing them)
- jj integration (no one has this...)
- Automations
- Integrated GitLab/GitHub review support
- `/btw` or `/side` commands

---

## My dev setup

| | |
| --- | --- |
| **Devices** | Mac Mini, MacBook Pro, iPhone, work MacBook Pro |
| **Network** | All on the same Tailscale network |

```
                    ┌───────────── Tailscale ─────────────┐
                    │                                     │
   Personal         │   ┌───────────┐   ┌─────────────┐   │
                    │   │ Mac Mini  │   │ MacBook Pro │   │
                    │   │(always on)│   │  (laptop)   │   │
                    │   └───────────┘   └─────────────┘   │
                    │           |        |                │
                    │          ┌──────────┐               │
                    │          │  iPhone  │               │
                    │          └──────────┘               │
                    │                |                    │
   Work             │       ┌──────────────────┐          │
                    │       │ work MacBook Pro │          │
                    │       └──────────────────┘          │
                    └─────────────────────────────────────┘
```

### AI subs

- **Work:** Everything's through the API/Codex Sub, so I can use Claude in any harness, and I can use Codex in any harness.
- **Personal:** I have a Claude and Codex sub because paying for the API is ridiculous, which means that to use it I have to use Claude Code, even though Claude Code is my least favorite of all the harnesses.

```
   Work      API ─────┬──► Claude ──┐
                      └──► Codex  ──┴──► any harness

   Personal  Claude sub ──────────────► Claude Code only
             Codex sub  ──────────────► pi / opencode
```

---

## Workflows

3 workflows currently active and testing: [Rex](#rex), [T3Code](#t3code), [Monocode](#monocode).

### Rex

#### Setup

I have the Rex app installed on my personal laptop, my work laptop, my Mac Mini, and I have the iOS app. They're all on Tailscale, they're all connected to each other. My phone can see my work laptop or my Mac Mini or my personal laptop. My Mac Mini and my laptop are not connected to my work laptop.

I can spin up Claude threads to use my Claude sub and pi or opencode threads using my Codex sub.

```
   ┌──────────┐◄──────────────►┌─────────────────┐
   │ Mac Mini │                │ personal laptop │
   └──────────┘                └─────────────────┘
        ▲                               ▲
        │         ┌────────┐            │
        └────────►│ iPhone │◄───────────┘
                  └────────┘
                      ▲
                      │
             ┌──────────────────┐
             │   work laptop    │   (not connected to
             └──────────────────┘    Mac Mini / laptop)
```

#### Notes

- This one works incredibly well. Rex is one of the best products that's been built in the last years.
- My only issue is just the added bit of friction of working in a terminal from your phone and losing some of the UI niceness that you get from working in a GUI (voice transcription, for example...cmon iOS).
- Historically, I'm a terminal person. Neovim, tmux, WezTerm/Ghostty for life. But as I stop working so deeply in the code and in the terminal, there's actually quite a bit with agents that you can get out of a GUI that you lose in a TUI-like application like Rex. Though they may change that in the future.

### T3Code

#### Setup

I have a T3 server on my work laptop paired to my phone, and a T3 server on my Mac Mini paired to my personal laptop and my phone.

It has my opencode, pi, Claude, and Codex providers connected to it.

```
   ┌──────────────────────┐         ┌────────┐
   │ work laptop          │────────►│ iPhone │
   │  [T3 server]         │         └────────┘
   └──────────────────────┘              ▲
                                         │
   ┌──────────────────────┐              │
   │ Mac Mini             │──────────────┘
   │  [T3 server]         │                 
   └──────────────────────┘──────────►┌─────────────────┐
                                      │ personal laptop │
                                      └─────────────────┘

   Providers: opencode · pi · Claude · Codex · opencode
```

#### Notes

- The UI is just not my favorite. It's good in many regards, but the aesthetics are not there. It's not native. Has not macOS glass. Is pure black. It doesn't have my side chat preference. And many of the UX choices are just things that I don't personally prefer. Feels far from my favorite aesthetic and far from a terminal.
- However, it definitely has the best flow across my headless server, laptops, and phones. Picking up and managing work is seamless.

### Monocode

#### Setup

I have the app, the native app, on my work laptop and my personal laptop, with a host on my Mac Mini. I have the iOS app paired to my laptop.

```
   ┌─────────────────┐       ┌─────────────────┐
   │   work laptop   │       │ personal laptop │◄────── iPhone
   │  [desktop app]  │       │  [desktop app]  │   (paired to ONE
   └─────────────────┘       └─────────────────┘    desktop client)
                                      │
                                      ▼
                             ┌─────────────────┐
                             │    Mac Mini     │
                             │     [host]      │
                             └─────────────────┘

   Problem: sessions spawned on the remote host aren't
   reliably visible to the clients.
```

#### Notes

- The UI is unbelievable, and monos are great.
- The main shortfall is the client-server architecture.
  - Using monos on repos with a remote host has a bunch of issues with it seeing sessions spawned on the remote host.
  - Likewise, you can only pair the app to a single desktop client. So I can't manage work on my work laptop and my personal laptop from my phone.
  - I also don't really want to manage work on my laptop because my laptop gets closed all the time. I want it to be on my Mac Mini and to be able to pick it up and resume it from my laptop or my phone.
- The UI/UX is the best in class for anything that's not the terminal. It's the only reason I still run it despite its obvious shortfalls as it comes to my considerations.
- So, my goal is actually to contribute to it to get it to work for me, because I like the design and the approach of it so much.

---
