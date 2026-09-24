MHF Local Stack — Troubleshooting Cheat Sheet
Golden rule

Check the global Docker cap first. 90% of "the machine is dying" problems come back to Docker exceeding its systemd memory cap, not individual containers.
bash

systemctl show docker.service | grep -E "Memory(Max|High)|CPUQuota"

Expected:
text

MemoryHigh=2040109465        # 1.9 GiB
MemoryMax=2362232012         # 2.2 GiB
CPUQuotaPerSecUSec=1s        # 100% of one core

If MemoryMax is missing or infinity → the drop-in didn't load. See "Reset the global cap" below.
Quick health check (run these first when something feels wrong)
bash

# 1. Host memory and swap
free -h

# 2. Docker global cap active?
systemctl show docker.service | grep -E "Memory(Max|High)"

# 3. Container usage vs limits
docker stats --no-stream

# 4. What's actually eating host RAM
ps aux --sort=-%mem | head -10

# 5. Is zram swap active?
swapon --show

Reads:

    free -h — if available is under ~1.5 GB and swap usage climbing → danger zone.

    docker stats — sum the "used" column. If total > 2.0 GB, close to the global cap.

    ps aux — IntelliJ + browser + Docker together is usually the culprit.

Terminology
systemd

Unit — anything systemd manages (a service, socket, timer, mount). Each has a name like docker.service and a config file. Docker uses docker.service (the daemon), docker.socket (wake-on-demand socket), and containerd.service (the runtime underneath).

Drop-in — an override file that adds to or changes a unit's config without editing the original. Systemd reads the base unit file, then applies drop-ins from /etc/systemd/system/<unit>.d/*.conf on top. Package updates replace the base file; your drop-in survives. That's why we put the memory caps there.

daemon-reload — makes systemd re-read unit files. It does not restart services; you still need systemctl restart. Use after editing any drop-in:
bash

sudo systemctl daemon-reload

systemctl edit <unit> — a wrapper that creates the drop-in directory if needed, opens /etc/systemd/system/<unit>.d/override.conf in your editor, and prompts to reload after saving. Gemini's approach used this; the alternative is mkdir + tee to write the same file manually. Same result.

MemoryHigh — soft limit. At this threshold, the kernel starts reclaiming aggressively (dropping caches, compressing, swapping). Pressure signal, not a wall.

MemoryMax — hard limit. At this threshold, the kernel OOM-kills something in the cgroup. The wall.

StartupMemoryHigh / StartupMemoryMax — same limits, applied only during the unit's startup phase. infinity means "no special startup limit; normal limits apply throughout."

CPUQuota — CPU cap as a percentage of one core. CPUQuota=100% means "one core's worth of CPU time." On a 2-core/4-thread machine, Docker can use at most one core.

CPUAccounting — tracks CPU usage for the cgroup. Required for CPUQuota to work.

CPUQuotaPerSecUSec=1s — the effective quota: 1 second of CPU per second of wall clock = 100% of one core.
Containers / Docker

Cgroup — a Linux kernel feature that groups processes and applies limits (memory, CPU, I/O). Every container is at least one cgroup. Your setup nests them:
text

systemd: docker.service  [MemoryMax=2.2G]
├─ keycloak container   [memory=1024M]
├─ novu-api container   [memory=448M]
└─ ...

If the sum exceeds 2.2G, the outer cgroup OOM-kills a container.

OOM killer — when a cgroup can't reclaim enough memory, the kernel kills a process. A killed container shows OOMKilled=true in docker inspect. Exit code 137 (128 + 9).

RSS (Resident Set Size) — actual physical RAM a process is using right now. The RSS column in ps aux. This is what costs you RAM; VSZ can be huge and mostly unused.

Buff/cache — RAM Linux uses for disk caching. Reclaimable — the kernel drops it instantly when apps need RAM. That's why available in free -h is what matters, not free.

Swap — disk or compressed RAM used as overflow when physical RAM is full.

    Disk swap (/swapfile) — slow, hits SSD, causes frozen-machine thrashing.

    zram swap (/dev/zram0) — compressed RAM, fast, trades CPU for RAM.

zram — a kernel module creating block devices backed by compressed RAM. zram-size = ram / 2 = ~3.8 GB on 8 GB. In swapon --show, higher PRIO = used first. Your zram (PRIO 100) is preferred over the swapfile (PRIO -1).

Bind mount — a host directory mapped into the container. Example: ./databases/keycloak-db:/var/lib/postgresql/data. Contrast with volumes, which are Docker-managed storage.

Port mapping — "9080:8080" means host port 9080 → container port 8080. Inside the Docker network, containers talk on the container's port (mhf-mailpit:1025). From your host/browser, use the host port (localhost:9080).

Docker socket — /var/run/docker.sock, a Unix socket the Docker CLI uses to talk to the daemon. When the daemon is stopped, the socket doesn't exist:
text

dial unix /var/run/docker.sock: connect: no such file or directory

Not a bug — Docker just isn't running.
Compose

Profile — a named group of services. Services tagged profiles: ["debug"] don't start with a normal up -d. Enable with docker compose --profile debug up -d. Used to keep optional services out of the default set.

depends_on: condition: service_healthy — wait until a dependency's healthcheck reports healthy before starting this service. Prevents "DB not ready" errors.

Healthcheck — a command Docker runs periodically inside the container. Exit code 0 = healthy, non-zero = unhealthy.

CMD vs CMD-SHELL — in a healthcheck:

    CMD runs the command directly. No shell, so || and exit become arguments, not operators.

    CMD-SHELL runs the string through /bin/sh -c, so shell syntax works.

The pgAdmin healthcheck originally used CMD with || exit 1 — that's why it always failed.
Keycloak

Realm — a namespace for users, clients, roles, and settings. You have two: master (admin) and mentalhealthforum (the app). Realms are isolated — a user in one is not a user in the other.

Client — an app that authenticates via Keycloak. Yours: mhf-frontend (SPA), mhf-backend (confidential), mhf-api (bearer-only).

kcadm.sh — Keycloak's admin CLI, runs inside the container. Authenticate against master first:
bash

kcadm.sh config credentials --server http://localhost:8080 --realm master --user X --password Y

Inside the container, Keycloak is on 8080 — the 9080 mapping is only for host access.

KEYCLOAK_ADMIN env var — bootstraps the initial admin only on the first start with an empty DB. After that, it's ignored; the user in the DB is what counts.

start-dev vs start — development mode (auto-reload, relaxed security) vs. production mode (requires hostname/TLS). You're on start-dev; would need to change for deployment.
Errors

SIGSEGV — segmentation fault. A process accessed memory it shouldn't have. Exit code 139 (128 + 11). In JVM terms, usually a native-code or memory-pressure crash.

OOM-kill — memory kill. Exit code 137 (128 + 9). Different cause, similar symptom.
Docker won't start / won't respond

Docker is disabled at boot by design. Start it manually:
bash

sudo systemctl start docker.service
sudo systemctl status docker.service     # confirm it came up
docker ps                                 # confirm the daemon answers

Stop it when done to free ~2 GB:
bash

sudo systemctl stop docker.service

Don't re-enable it at boot — that was a deliberate choice.

If you see:
text

failed to connect to the docker API at unix:///var/run/docker.sock
dial unix /var/run/docker.sock: connect: no such file or directory

...it means Docker is stopped. Not a bug. Run the start command above.
Keycloak crash-loops or won't boot
bash

# 1. What's the exit state?
docker inspect mhf-keycloak --format '{{.State.ExitCode}} {{.State.OOMKilled}} {{.State.Status}}'

# 2. What's it saying?
docker logs --tail 50 mhf-keycloak

# 3. Is its memory cap active?
docker inspect mhf-keycloak --format '{{.HostConfig.Memory}}'

Exit code 1 + log says Multiple garbage collectors selected
→ Someone added a GC flag to JAVA_OPTS_APPEND. Remove it. The Keycloak image already sets one.

Exit code 137 or OOMKilled=true
→ The container blew past its limit. Check current usage:
bash

docker stats --no-stream mhf-keycloak

If usage is pinned near the limit, raise it (in compose) and recreate:
bash

docker compose up -d keycloak

Log says Error occurred during initialization of VM
→ JVM flags are wrong. The correct line in compose is:
yaml

JAVA_OPTS_APPEND: "-Xms256m -Xmx512m -XX:MaxMetaspaceSize=160m -XX:MaxDirectMemorySize=48m"

Do NOT add -XX:+UseSerialGC.
Login fails

Work through in order — these are the known failure points:
bash

# 1. Is Keycloak reachable?
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9080/realms/mentalhealthforum
# Expect 200 or 302. If 000, Keycloak isn't up.

# 2. Check the login attempt in logs
docker logs --since 2m mhf-keycloak | grep -iE "LOGIN_ERROR|user_not_found|error"

# 3. List real users in the realm
docker exec -it mhf-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
--server http://localhost:8080 --realm master --user mhf-superadmin --password <admin-password>
docker exec -it mhf-keycloak /opt/keycloak/bin/kcadm.sh get users -r mentalhealthforum --fields username,enabled

Key reminder: mhf-superadmin lives in the master realm. It does not exist in mentalhealthforum. Don't try to log into the forum with it — use a user from the list (e.g. jose.garcia).

Port reminder: Keycloak is at http://localhost:9080 on the host, not 8080. Inside the container it's 8080.
Emails aren't arriving (Novu / MFA)
bash

# 1. Is Mailpit up?
docker compose ps mailpit

# 2. Open the inbox
# Browser: http://localhost:8025

# 3. Can Novu reach Mailpit?
docker exec mhf-novu-api wget -q -O - http://mhf-mailpit:8025 || echo "unreachable"

Novu SMTP config should be:

    Host: mhf-mailpit

    Port: 1025

    Username / Password: anything (e.g. dev / dev)

    TLS: off

    From: anything (e.g. noreply@mhf.local)

Mailpit clears on restart. That's intentional. If you restarted Mailpit, the inbox is empty — send a new test.

Testing the SMTP port directly: wget speaks HTTP, not SMTP. When you hit port 1025 with wget, you'll see 220 ... Mailpit ESMTP Service ready — that's Mailpit's SMTP greeting. The "error" wget reports is expected. The connection worked.
pgAdmin shows unhealthy

You may see (unhealthy) in docker compose ps. It's usually a false alarm — the check uses wget --spider against /misc/ping, and occasionally pgAdmin's readiness lags. Verify:
bash

docker exec mhf-pgadmin wget -q --spider http://localhost:80/misc/ping && echo OK

If that says OK, pgAdmin is fine. Ignore the health status.

To start pgAdmin (it's behind the debug profile):
bash

docker compose --profile debug up -d pgadmin

The stack is eating all my RAM

Run the containers in tiers. Use profiles and manual starts.
bash

# Core only: Keycloak + DBs + Mailpit (no Novu, no debug)
docker compose up -d keycloak keycloak-db forum-db mailpit

# Add Novu when testing notifications
docker compose up -d mhf-novu-mongodb mhf-novu-redis mhf-novu-api mhf-novu-worker mhf-novu-ws mhf-novu-dashboard

# Add debug tools when inspecting
docker compose --profile debug up -d pgadmin mhf-novu-mongo-express

# Stop everything
docker compose down

Check what's running before you add more:
bash

docker stats --no-stream

Reset the global cap (if it's ever lost)
bash

sudo systemctl edit docker.service

Paste between the comment markers:
ini

[Service]
CPUAccounting=true
CPUQuota=100%
MemoryAccounting=true
MemoryHigh=1.9G
MemoryMax=2.2G

Save, then:
bash

sudo systemctl daemon-reload
sudo systemctl restart docker.service
systemctl show docker.service | grep -E "Memory(Max|High)|CPUQuota"

Expected: MemoryMax=2362232012, MemoryHigh=2040109465, CPUQuotaPerSecUSec=1s.
The machine has frozen / crashed

If it's still responding enough to run commands:
bash

# 1. Stop Docker immediately — reclaims ~2 GB
sudo systemctl stop docker.service

# 2. Free host RAM
free -h

If it's fully frozen, hard power-off, then on reboot:
bash

# What happened last boot?
journalctl -b -1 -p err --no-pager | tail -50

# Did Docker OOM?
journalctl -u docker --since "1 hour ago" | grep -iE "oom|killed|memory"

If you see oom-kill events tied to Docker → the global cap did its job (Docker died, not the kernel). Lower the per-service limits in compose.

If you see kernel-level errors, ext4 corruption, or hardware messages → check disk health:
bash

sudo dmesg | grep -iE "error|corrupt|ext4|nvme|ata"
sudo smartctl -a /dev/sda     # or nvme0n1

Things that must never change

    JAVA_OPTS_APPEND on Keycloak — no -XX:+UseSerialGC. Ever.

    Keycloak port on host is 9080 — not 8080.

    mhf-superadmin is master-realm only — never used for forum logins.

    Docker is disabled at boot — start it manually.

    The systemd cap is 2.2 GB — if the stack exceeds it, a container gets OOM-killed (acceptable). Without it, the kernel crashes (not acceptable).

Notes worth remembering

    Admin credentials gotcha: KEYCLOAK_ADMIN env vars only take effect on first boot. After that, the user in the database is what matters. If you can't log in as the admin, try mhf-superadmin — not mhf-temp-admin.

    The real memory hog is the IDE + browser, not Docker. Any time free is low, run ps aux --sort=-%mem | head -10 before blaming containers. IntelliJ alone can use ~1.8 GB; a browser with a few tabs another ~1.5 GB.

    Docker socket errors are normal when Docker is stopped. sudo systemctl start docker.service fixes it. Not a bug.

    novu-dashboard is the tightest container in the current stack (86% of 128M). If any Novu service OOMs, it'll be this one first. Bump it to 160M next time you edit the compose.

    pgAdmin / mongo-express require --profile debug. Their absence is intentional, not a failure.

When to stop debugging and just restart

If you've spent more than 10 minutes and the logs aren't showing something obvious:
bash

docker compose down
sudo systemctl restart docker.service
docker compose up -d

Nine times out of ten this clears transient state (stale sessions, stuck ports, orphaned networks). Debug from a clean slate.
When to stop tuning and change hardware

If any of these become true:

    You're regularly stopping the stack to free RAM for a browser tab

    You're avoiding starting Novu because of the memory cost

    The machine has frozen more than once in a month

    You're spending more time managing resources than writing code

→ The 8 GB ceiling is the problem, not the tuning. The paths out:

    Used mini PC (~$100–150, 8th-gen i5, 16 GB) on your LAN — runs the heavy services.

    Oracle Cloud Always Free — 4 cores / 24 GB ARM, free forever.

    Second-hand RAM — but slot 2 is dead, so this doesn't apply to you.

The project continues either way. The only question is on which machine.