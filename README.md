# DevOps Assignments

**Name:** Utkarsh Bahuguna &nbsp;&nbsp;**Enrollment Number:** 10161

Solutions to the DevOps assignment set. **Each assignment is a self-contained folder** holding its write-up, its scripts and source, its raw command logs, and its screenshots.

**Every command output in this repository was captured by actually running it.** Nothing is illustrative or copied from documentation. Where something failed on this machine — a missing package, a genuinely broken feature — it is reported as it happened, with the diagnosis, rather than replaced with output that would look tidier.

---

## Assignments

| # | Folder | What it covers |
|---|---|---|
| 01 | [Linux Fundamentals](Linux%20Fundamentals/) | Hard vs soft links · `adduser` vs `useradd` · `journalctl` · command cheat sheet |
| 02 | [Shell Scripting](Shell%20Scripting/) | [`sysinfo.sh`](Shell%20Scripting/sysinfo.sh) — system report with user input and output redirection |
| 03 | [Git and GitHub](Git%20and%20GitHub/) | `git commit -a -m` vs `-m` · cherry-pick, including conflict resolution |
| 04 | [Networking](Networking/) | [`netcheck.sh`](Networking/netcheck.sh) — layered network troubleshooting report |
| 05 | [Docker Fundamentals](Docker%20Fundamentals/) | Five apps, five base images, running simultaneously |
| 06 | [Docker Images](Docker%20Images/) | Multi-stage build, measured against a single-stage control |
| 07 | [Docker Networking](Docker%20Networking/) | Custom bridges · host network · bind mounts · overlay + Swarm |

---

## Repository layout

Every folder follows the same shape: a `README.md` write-up, the source it documents, an `outputs/` directory of raw unedited command logs, and `screenshots/` where the assignment calls for them.

```
.
├── Linux Fundamentals/
│   ├── README.md
│   └── outputs/                   # links, users, journalctl, cheat sheet logs
│
├── Shell Scripting/
│   ├── README.md
│   ├── sysinfo.sh
│   └── outputs/
│
├── Git and GitHub/
│   ├── README.md
│   └── outputs/                   # commit-flag cases, cherry-pick transcript
│
├── Networking/
│   ├── README.md
│   ├── netcheck.sh
│   └── outputs/                   # success and NXDOMAIN failure reports
│
├── Docker Fundamentals/           # five stacks, one Dockerfile each
│   ├── README.md
│   ├── nodejs-app/                #   node:20            → host 3000
│   ├── python-app/                #   python:3.12        → host 5001
│   ├── java-app/                  #   eclipse-temurin:21 → host 8082
│   ├── nginx-app/                 #   nginx:alpine       → host 8081
│   ├── apache-app/                #   httpd:2.4          → host 8083
│   ├── outputs/
│   └── screenshots/
│
├── Docker Images/                 # multi-stage build     → host 8080
│   ├── README.md
│   ├── Dockerfile                 #   two stages
│   ├── Dockerfile.single-stage    #   control, for the size comparison
│   ├── server.js  package.json
│   ├── outputs/
│   └── screenshots/
│
└── Docker Networking/             # networking & volumes
    ├── README.md
    ├── bind-mount/index.html      #   mounted live into nginx
    ├── outputs/
    └── screenshots/
```

Each Docker app directory also contains a `script.sh` that builds and runs it in one step.

---

## Environment

Everything was executed on this machine:

```
$ uname -a
Linux Pottu-Lappy 7.0.0-30-generic #30-Ubuntu SMP PREEMPT_DYNAMIC x86_64 GNU/Linux

$ lsb_release -d
Description:	Ubuntu 26.04 LTS

$ docker --version
Docker version 29.1.3, build 29.1.3-0ubuntu4.1
```

Native Linux rather than Docker Desktop, which matters for two of the exercises: `--network host` binds the real host's ports, and the overlay driver runs against the real kernel.

---

## Port map

| Port | Service |
|---|---|
| 80 | Apache on the **host** network (Docker Networking, Task 2) |
| 3000 | Node.js app (`node:20`) |
| 5001 | Python Flask app (container port 5000) |
| 8080 | **Multi-stage** Node app |
| 8081 | Nginx static site |
| 8082 | Java app (container port 8080) |
| 8083 | Apache static site |
| 8085 | Apache with bridge networking + `-p` |
| 8090 | Nginx serving a **bind-mounted** directory |
| 8095 | Swarm service on an overlay network |

---

## Selected results

**Multi-stage builds, measured against a control** — same app, same `node:20-alpine` base, the only difference being the second stage:

```
nodejs-hello        1.59GB     node:20, single stage
single-stage-hello   414MB     node:20-alpine, single stage
multi-stage-hello    200MB     node:20-alpine, multi-stage      ← 8x smaller
```

The single-stage image also ships 228 extra `node_modules` directories and its own `Dockerfile` and `script.sh` into production. [Details →](Docker%20Images/README.md)

**Network isolation, verified in both directions** — the backend joins three networks and becomes the only path between the frontend and the database:

```
frontend → backend    ✅  0% packet loss
backend  → database   ✅  0% packet loss
frontend → database   ❌  ping: bad address 'database'
```

The failure is the point. [Details →](Docker%20Networking/README.md)

**Bind mounts share an inode, they do not copy:**

```
$ ls -i bind-mount/index.html                                   → 8284778
$ docker exec nginx-bind ls -i /usr/share/nginx/html/index.html → 8284778
```

---

## Things that did not work, and why

Recorded rather than papered over:

| Issue | Handling |
|---|---|
| `traceroute` is not installed on Ubuntu 26.04 | `netcheck.sh` falls back to `tracepath`, which needs no root |
| Docker Buildx not installed, so builds use the legacy builder | Documented; multi-stage semantics are unchanged, only the log format differs |
| Swarm ingress published port returned `000` on this host | Diagnosed (IPVS loaded, iptables backend) and reported honestly; overlay DNS, VIPs and container traffic all verified working |
| `journalctl -u ssh.service` was empty — no sshd on this laptop | `docker.service` used as the worked example instead |
| Cherry-picking a commit whose parent context was missing | Turned into the more useful lesson: the `modify/delete` conflict is documented and resolved |

---

*Utkarsh Bahuguna · 10161*
