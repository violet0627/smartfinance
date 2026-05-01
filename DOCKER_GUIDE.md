# Docker Guide — SmartFinance
### Everything you need to know, from the very beginning

---

## Part 1 — What is Docker, and Why Does It Exist?

### The Old Problem

Before Docker, running a backend project on a new machine required:

1. Install Python (the right version)
2. Install MySQL (configure username, password, port)
3. Install all Python packages (`pip install -r requirements.txt`)
4. Set up your `.env` file with the right values
5. Run database migrations manually
6. Figure out why it works on your laptop but not your friend's

Every machine is slightly different — different OS, different MySQL version, different environment variables. This is where the famous phrase comes from: *"it works on my machine."*

### What Docker Actually Does

Docker packages your entire application — Python, MySQL, all libraries, all config — into isolated units called **containers**. A container is like a mini virtual computer that has everything pre-installed and pre-configured.

You write a recipe once (the `Dockerfile` and `docker-compose.yml`). Docker follows that recipe to build identical environments everywhere.

**Old way:** Install Python + MySQL + pip install + configure + migrate → run  
**Docker way:** `docker-compose up`

That's the entire point. One command. Same result on every machine.

### Containers vs Virtual Machines

You might wonder: isn't this like a virtual machine (VM)?

| | Virtual Machine | Docker Container |
|---|---|---|
| Size | Gigabytes (full OS) | Megabytes (just the app layer) |
| Startup | Minutes | Seconds |
| What it includes | Full operating system | Only what your app needs |
| Purpose | Simulate an entire computer | Run one isolated service |

A VM pretends to be a whole computer. A container is surgical — it only isolates the application layer, not the whole OS. That's why containers are lightweight and fast.

### How SmartFinance Uses Docker

SmartFinance has two services running in Docker:

| Container | What it is | Port |
|---|---|---|
| `smartfinance_db` | MySQL 8.0 database | 3307 (host) → 3306 (container) |
| `smartfinance_backend` | Flask API server | 5000 |

The Flask container and MySQL container talk to each other over Docker's internal network. From the outside, you access Flask at `localhost:5000` and MySQL at `localhost:3307`.

---

## Part 2 — Installation on Windows

### Step 1: Download Docker Desktop

Go to [docker.com](https://www.docker.com) → Download Docker Desktop for Windows.

Docker Desktop is the program that manages everything. It gives you:
- A GUI to see running containers
- The `docker` and `docker-compose` commands in your terminal
- The Docker Engine (the actual engine that runs containers)

### Step 2: The Permission Error (and How to Fix It)

When you install Docker Desktop on Windows, it needs to create a folder at `C:\ProgramData\DockerDesktop`. If a previous failed install left that folder with wrong ownership, Docker cannot write to it, and installation fails with an error like:

```
C:\ProgramData\DockerDesktop must be owned by an elevated account
```

**Why this happens:** A previous install attempt created the folder, but the install failed midway. The folder was left behind with incorrect ownership — it belongs to a non-elevated account. Docker's installer checks ownership for security reasons and refuses to proceed.

**Fix — run these commands in PowerShell as Administrator:**

```powershell
# 1. Take ownership of the folder
takeown /f "C:\ProgramData\DockerDesktop" /r /d y

# 2. Give Administrators full control
icacls "C:\ProgramData\DockerDesktop" /grant Administrators:F /t

# 3. Delete the folder so the installer can recreate it cleanly
Remove-Item -Recurse -Force "C:\ProgramData\DockerDesktop"
```

Then run the installer again. This time it works.

**How to open PowerShell as Administrator:**  
Press Windows key → type "PowerShell" → right-click → "Run as administrator"

### Step 3: The Subscription Agreement

When Docker Desktop opens for the first time, it shows a "Docker Subscription Service Agreement."

This is **free** for personal use, students, and small teams. You do not need to pay anything. Accept the agreement and continue.

### Step 4: WSL (Windows Subsystem for Linux)

Docker Desktop on Windows uses WSL — a feature that lets Windows run a Linux environment internally. Linux is Docker's native home; WSL is what makes Docker work on Windows without a full virtual machine.

When Docker starts, a terminal might appear saying "WSL needs to be updated." Press any key to let it install. This is a one-time setup.

After WSL installs, Docker Desktop finishes starting. You'll see a green dot labeled "Engine running" in the bottom left. That means Docker is ready.

---

## Part 3 — Project Structure: What Docker Uses

### The Dockerfile

`backend/Dockerfile` is the recipe for building the Flask container:

```dockerfile
FROM python:3.11-slim          # Start from an official Python 3.11 image
WORKDIR /app                   # All commands run from /app inside the container
COPY requirements.txt .        # Copy this first (Docker caches this layer)
RUN pip install -r requirements.txt  # Install Python packages
COPY . .                       # Copy the rest of the source code
EXPOSE 5000                    # Tell Docker this container listens on port 5000
CMD ["python", "run.py"]       # Start Flask when the container starts
```

**Why copy `requirements.txt` before the rest of the code?**  
Docker builds images in layers. If `requirements.txt` hasn't changed, Docker reuses the cached `pip install` layer and skips reinstalling packages. This makes rebuilds much faster.

### docker-compose.yml

`docker-compose.yml` is the recipe for running *multiple containers together*. It defines:
- Two services: `db` (MySQL) and `backend` (Flask)
- How they connect to each other
- Which ports to expose
- What environment variables to set

Key section to understand:

```yaml
environment:
  DB_HOST: db        # 'db' is the service name above — Docker resolves it to the MySQL container's IP
  DB_PORT: 3306      # Internal container port (NOT 3307 — that's only for host access)
```

When Flask runs inside Docker, it connects to MySQL using the hostname `db`. Docker has its own internal DNS that resolves `db` to the MySQL container's IP address. This is how containers talk to each other.

### Why Port 3307 (not 3306)?

```yaml
ports:
  - "3307:3306"   # host:container
```

This means: expose container port 3306 as host port 3307.

If you already have MySQL installed locally on your laptop, it's already using port 3306. Using 3307 on the host avoids a conflict — your local MySQL and Docker MySQL can coexist without fighting over the same port.

Flask inside Docker still connects to MySQL on port 3306 because that's the *container-internal* port. The 3307 mapping is only for access from *outside* Docker (e.g., if you want to connect with DBeaver or MySQL Workbench from your laptop).

---

## Part 4 — How Table Creation Works (Important!)

### db.create_all() vs SQL files

When Flask starts, it runs `db.create_all()`. This tells SQLAlchemy to look at all the model classes (`User`, `Transaction`, `Budget`, etc.) and create the corresponding MySQL tables if they don't exist.

This is the **only** way tables are created in this project.

**The mistake we made (and fixed):** An early version of `docker-compose.yml` mounted SQL migration files into MySQL's `docker-entrypoint-initdb.d/` folder. MySQL runs any `.sql` files in that folder on first startup. This created all the tables before Flask started.

Then when Flask started and ran `db.create_all()`, it tried to create the same tables *again*. MySQL doesn't fail on duplicate tables, but it does fail on duplicate foreign key constraint names — MySQL requires FK names to be unique across the entire schema. Result: crash.

**The fix:** Remove all SQL file mounts. Let `db.create_all()` do everything.

```yaml
# REMOVED — this caused the duplicate table conflict:
# volumes:
#   - ./backend/migrations/create_goals_table.sql:/docker-entrypoint-initdb.d/01_goals.sql
```

**Rule to remember:** In this project, `db.create_all()` owns table creation. SQL migration files are kept as reference only — they are not run automatically.

---

## Part 5 — First Run

### Running docker-compose for the first time

In your project folder (where `docker-compose.yml` is):

```powershell
docker-compose up
```

What happens step by step:
1. Docker reads `docker-compose.yml`
2. Pulls `mysql:8.0` from Docker Hub (first time only — cached after)
3. Builds the Flask image using `backend/Dockerfile` (first time only — cached after)
4. Starts the MySQL container
5. Waits for MySQL to be healthy (the healthcheck pings MySQL every 10 seconds)
6. Once MySQL is healthy, starts the Flask container
7. Flask's `run.py` executes → `db.create_all()` creates all tables → Flask starts listening on port 5000

You'll see log output from both containers interleaved. Flask logs look like:
```
backend  | * Running on http://0.0.0.0:5000
backend  | * Debug mode: on
```

MySQL logs look like:
```
db       | [System] [MY-011323] [Server] X Plugin ready for connections.
```

### Verifying the backend is alive

Open a new PowerShell window (keep docker-compose running in the first one):

```powershell
Invoke-WebRequest -Uri "http://localhost:5000/api/auth/health" -UseBasicParsing
```

Or just open your browser and go to `http://localhost:5000/api/auth/health`.

If Flask is running, you get a 200 response. If not, check the logs.

---

## Part 6 — Errors We Hit (and What They Taught Us)

### Error 1: Duplicate foreign key constraint name

```
sqlalchemy.exc.OperationalError: (pymysql.err.OperationalError) (1826,
"Duplicate foreign key constraint name 'emailverificationtokens_ibfk_1'")
```

**What happened:** Both the SQL migration files AND `db.create_all()` tried to create the same tables. FK names must be unique per schema in MySQL.

**Why it matters:** This taught us that two systems cannot both own table creation. Pick one. In this project, `db.create_all()` wins.

**Fix:** Remove SQL file mounts from `docker-compose.yml`.

---

### Error 2: SyntaxError in financial_insights.py

```
SyntaxError: f-string: expecting '}'
```

**What happened:** The code had nested quotes inside an f-string:

```python
# Python 3.12+ syntax (does NOT work in 3.11):
f'You have {count} goal{"s" if count > 1 else ""}'
```

The container uses Python 3.11. Python 3.11 does not allow quotes inside f-string expressions. Python 3.12 added this feature.

**Fix:** Extract the suffix to a variable first:

```python
# Python 3.11 compatible:
goal_suffix = "s" if count > 1 else ""
f'You have {count} goal{goal_suffix}'
```

**Why it matters:** The version of Python on your laptop might differ from the version in the container. Always check which Python version the Dockerfile uses, and write code compatible with that version.

---

### Error 3: Achievements table doesn't exist (seed SQL)

```
ERROR 1146 (42S02): Table 'smartfinance.Achievements' doesn't exist
```

**What happened:** We tried to insert seed data into the Achievements table by mounting `seed_achievements.sql` in `docker-entrypoint-initdb.d/`. MySQL runs these scripts during initialization — before Flask has started — so the Achievements table doesn't exist yet (it gets created by Flask's `db.create_all()`).

**Why it matters:** Docker's MySQL initialization runs at container startup, which is before Flask runs. You can't seed data into tables that haven't been created yet.

**Fix:** Don't mount seed SQL files. The Achievements table exists (empty) after `db.create_all()`. Seed data can be added later via a Flask endpoint or a separate script that runs after Flask starts.

---

### Error 4: INSTALL_FAILED_INSUFFICIENT_STORAGE (emulator)

This is an Android emulator error, not Docker. The emulator's virtual storage was full.

**Fix:** Android Studio → Device Manager → right-click the emulator → Wipe Data.

This deletes the emulator's fake internal storage (like factory-resetting a phone). Your real project code is not affected — it lives on your actual laptop. After wiping, run the app again.

---

## Part 7 — Daily Startup Routine

Every time you come back to work:

### Option A (recommended): Auto-start Docker

Docker Desktop → Settings → General → tick **"Start Docker Desktop when you sign in"**

Then your routine is:
1. Turn on laptop (Docker auto-starts in background)
2. Open your project folder in terminal
3. `docker-compose up -d`
4. Open Android Studio → run the app

### Option B: Manual start

1. Open Docker Desktop → wait for green "Engine running" dot
2. In your project folder: `docker-compose up -d`
3. Open Android Studio → run the app

### The `-d` flag

`docker-compose up -d` runs containers in the background (detached mode). Your terminal is free for other commands. Containers keep running until you stop them.

`docker-compose up` (no `-d`) shows live logs in the terminal. Useful for debugging. Containers stop when you press Ctrl+C.

---

## Part 8 — Data Persistence

This is the most common source of confusion with Docker. Here's the definitive answer:

| Action | Your database data | Why |
|---|---|---|
| Close Android Studio | **Safe** | Android Studio only connects to the backend; it doesn't control Docker |
| Close Docker Desktop | **Safe** | Data is in a named volume on your machine, not in RAM |
| Restart your laptop | **Safe** | Volume persists across reboots |
| `docker-compose down` | **Safe** | Stops containers but keeps the volume |
| `docker-compose down -v` | **DELETED** | The `-v` flag explicitly deletes named volumes |

### What is a named volume?

```yaml
volumes:
  - mysql_data:/var/lib/mysql
```

`mysql_data` is a named volume — a folder managed by Docker that lives on your real laptop. When the MySQL container writes data, it writes to `mysql_data`. When the container restarts, it reads from `mysql_data`. The data outlives any individual container.

`docker-compose down -v` deletes named volumes. Use it only when you intentionally want a clean slate (e.g., to re-run migrations from scratch, or to fix a corrupted database state).

### Do I need to run docker-compose down before closing?

**No.** You can close Android Studio and Docker Desktop without running `docker-compose down`. Your data is safe.

`docker-compose down` is just a clean way to stop containers. It's the equivalent of gracefully shutting down vs just unplugging the power. Both work; graceful shutdown is tidier.

---

## Part 9 — Flutter App Configuration

File: `lib/config.dart`

```dart
static const String _serverIp = '10.0.2.2';
static const int _serverPort = 5000;
```

### Why 10.0.2.2?

When you run the Android emulator on your laptop, the emulator is a virtual phone. Inside that virtual phone, `localhost` refers to the emulator itself — not your laptop.

Android emulators have a special IP address `10.0.2.2` that maps to the host machine's `localhost`. So:

- Your laptop runs Docker → Flask is at `localhost:5000`
- The emulator connects to `10.0.2.2:5000` → which resolves to your laptop's `localhost:5000`
- Result: the emulator reaches Flask

| Situation | IP to use |
|---|---|
| Android emulator + Docker | `10.0.2.2` |
| Physical Android phone (same WiFi) | Your laptop's IPv4 (run `ipconfig` in CMD) |
| iOS simulator | `127.0.0.1` or `localhost` |
| Demo day (university WiFi) | Your laptop's IPv4 on that network |

**On demo day:** Connect your laptop to university WiFi → run `ipconfig` → find the IPv4 address under the Wi-Fi adapter (e.g. `192.168.x.x`) → update `_serverIp` in `lib/config.dart` → rebuild the app.

---

## Part 10 — Multiple Projects with Docker

Each project needs its own `docker-compose.yml`. The only constraint: **port numbers must be different**.

```yaml
# SmartFinance (this project)
ports:
  - "5000:5000"   # Flask
  - "3307:3306"   # MySQL

# Another project (use different host ports)
ports:
  - "5001:5000"   # Flask  
  - "3308:3306"   # MySQL
```

As long as the host-side ports (the left numbers) are different, both projects can run simultaneously. Docker handles the routing internally.

---

## Part 11 — All Commands Reference

```powershell
# Start everything (background — terminal stays free)
docker-compose up -d

# Start everything (foreground — see live logs)
docker-compose up

# Stop everything (data stays safe)
docker-compose down

# Stop + DELETE all database data (fresh start)
docker-compose down -v

# Watch Flask logs live (useful for debugging)
docker-compose logs -f backend

# Watch MySQL logs live
docker-compose logs -f db

# Run pytest tests inside the Flask container
docker-compose exec backend pytest tests/

# Open a shell inside the Flask container (for manual inspection)
docker-compose exec backend bash

# Rebuild the Flask image (after changing Dockerfile or requirements.txt)
docker-compose up --build

# Check which containers are running
docker ps

# Check all containers including stopped ones
docker ps -a

# See all named volumes on your machine
docker volume ls

# Delete a specific volume
docker volume rm smartfinance2_mysql_data
```

---

## Part 12 — Troubleshooting

### Backend crashes on startup

```powershell
docker-compose logs backend
```

Read the error. Common causes:
- Python syntax error in your code
- Missing environment variable
- Database not ready yet (healthcheck should prevent this, but sometimes timing is off — wait 10 seconds and try again)

### Database conflict / duplicate tables

```powershell
docker-compose down -v
docker-compose up
```

This wipes the database and starts completely fresh. `db.create_all()` recreates all tables.

### Port already in use

```
Error: Bind for 0.0.0.0:5000 failed: port is already allocated
```

Another process is using port 5000 (or 3307). Either stop that process, or change the host port in `docker-compose.yml`:

```yaml
ports:
  - "5001:5000"   # Use 5001 instead of 5000
```

Then update `lib/config.dart` to match: `static const int _serverPort = 5001;`

### Emulator can't connect to backend

Check in order:
1. Is `docker-compose up` running? (Check Docker Desktop — you should see green containers)
2. Is `lib/config.dart` using `10.0.2.2`?
3. Is Docker Desktop open and showing "Engine running"?
4. Try `Invoke-WebRequest -Uri "http://localhost:5000/api/auth/health" -UseBasicParsing` from PowerShell — if this fails, the issue is Docker, not the emulator

### WSL error on Docker startup

Docker needs WSL to run on Windows. If Docker Desktop shows a WSL error:
- Open PowerShell as Administrator
- Run: `wsl --update`
- Restart Docker Desktop

### Docker Desktop won't install (permission error on C:\ProgramData\DockerDesktop)

```powershell
# Run these in PowerShell as Administrator
takeown /f "C:\ProgramData\DockerDesktop" /r /d y
icacls "C:\ProgramData\DockerDesktop" /grant Administrators:F /t
Remove-Item -Recurse -Force "C:\ProgramData\DockerDesktop"
```

Then run the Docker Desktop installer again.

---

## Part 13 — The Big Picture (Why This Matters for Your Internship)

Docker is industry standard. Every serious tech company uses containers. When you join an internship, you will likely see:

- A `Dockerfile` in the repo
- A `docker-compose.yml` for local development
- CI/CD pipelines that build and deploy Docker images
- Staging and production environments running on Kubernetes (orchestrated containers)

What you learned by setting up Docker for SmartFinance:

| Concept | What you did |
|---|---|
| Container images | Built the Flask image from a Dockerfile |
| Multi-container apps | Ran Flask + MySQL together with docker-compose |
| Environment variables | Configured the backend to connect to the database without hardcoding values |
| Named volumes | Understood why database data survives container restarts |
| Port mapping | Understood host:container port syntax and why 3307:3306 |
| Container networking | Understood why Flask uses hostname `db` to reach MySQL |
| Healthchecks | Understood why MySQL needs to be healthy before Flask starts |
| Layer caching | Understood why requirements.txt is copied before the rest of the code |
| Debugging | Read container logs to diagnose crashes |

You also hit real production-level bugs — the duplicate FK constraint, the Python version f-string incompatibility — and fixed them. That's the actual internship experience.
