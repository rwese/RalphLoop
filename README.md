# RalphLoop - Autonomous Resilience Experiment

## 🎯 What Is This?

RalphLoop is an autonomous development system that runs itself to achieve goals while continuously improving. It demonstrates the concept of a self-sustaining development process that can:

- 🏃 Run autonomously to achieve objectives
- 🔧 Handle problems and recover automatically
- 📦 Produce useful products while evolving
- 🛡️ Maintain maximum resilience to never die
- 🌱 Create new evolutions of code and information

## 🚀 Quick Start

### Option 1: Run the Autonomous Loop

```bash
# Run single iteration for testing
./ralph.sh 1

# Run 10 iterations (default is 100)
./ralph.sh 10

# Run full autonomous mode
./ralph.sh
```

### Option 2: Use the Web Application

The "Simple Choice" implementation is a Quick Notes web application:

```bash
# Open in browser
open quick-notes/index.html

# Or start a simple server
python3 -m http.server 8080
# Then visit http://localhost:8080/quick-notes/
```

## 📁 Project Structure

```
RalphLoop/
├── quick-notes/          # 🏆 Simple Choice POC - Quick Notes Web App
│   └── index.html        # Complete single-page web application
├── docs/                 # 📚 Documentation
│   ├── SETUP.md          # Complete Gastown setup guide
│   └── DOCKER_CHOICES.md # Dockerfile decision matrix
├── progress.md           # 📊 Experiment progress tracking
├── prompt.md             # 🎯 Core experiment objectives
├── ralph.sh              # 🤖 Autonomous loop script
├── Dockerfile            # Container configuration
└── .gitignore            # Git ignore rules
```

## 🎨 Simple Choice: Quick Notes Web Application

**Selected Product:** Quick Note Capture

**Why This Choice:**

- ✅ Simplest to implement (text storage + retrieval)
- ✅ Solves real problem (capturing ideas quickly)
- ✅ High user demand (everyone loses ideas)
- ✅ Can start minimal and grow (tags, search, sync)
- ✅ Works well as web application
- ✅ Perfect for demonstrating resilience loop

**Features Implemented:**

- ⚡ Quick capture with 'N' keyboard shortcut
- 💾 Local storage persistence (works offline)
- 🔍 Search functionality
- 📅 Timestamps and metadata
- 🗑️ Delete with confirmation
- 🌙 Dark mode UI
- 📱 Responsive design

**Elevator Pitch:**

> "Capture ideas anywhere with one keystroke. Lightning fast, works offline, syncs everywhere. No more lost brilliant ideas."

## 🏃 How the Loop Works

The `ralph.sh` script implements an autonomous development loop:

```
┌─────────────────────────────────────┐
│  1. Read Current State              │
│     - progress.md                   │
│     - prompt.md                     │
│     - Git status                    │
└──────────────────┬──────────────────┘
                   ▼
┌─────────────────────────────────────┐
│  2. Analyze & Prioritize            │
│     - Decide highest priority task  │
│     - Plan implementation           │
└──────────────────┬──────────────────┘
                   ▼
┌─────────────────────────────────────┐
│  3. Execute Task                    │
│     - Implement features            │
│     - Write tests if needed         │
│     - Update documentation          │
└──────────────────┬──────────────────┘
                   ▼
┌─────────────────────────────────────┐
│  4. Commit & Track                  │
│     - Git add & commit              │
│     - Update progress.md            │
└──────────────────┬──────────────────┘
                   ▼
┌─────────────────────────────────────┐
│  5. Iterate                         │
│     - Check completion status       │
│     - Continue or complete          │
└─────────────────────────────────────┘
```

## 🔧 Development Options

### Native Development

```bash
# Edit the web application
open quick-notes/index.html

# Run the autonomous loop
./ralph.sh 1

# Check git status
git status
git log --oneline
```

### Docker Development

```bash
# Build minimal image
docker build -f Dockerfile.minimal -t ralphloop:minimal .

# Run with volume mount
docker run -it --rm \
  -v $(pwd):/workspace \
  ralphloop:minimal
```

### Containerized Loop (Podman)

```bash
# Run loop in container
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  localhost/opencode-dev bash ./ralph.sh 1
```

## 📊 Progress Tracking

The experiment tracks progress in `progress.md`:

- ✅ **Foundation Setup** - Documentation, analysis, requirements
- 🚧 **Product Development** - Building MVP, adding features
- 📈 **Resilience Features** - Auto-save, sync, offline support
- 🎯 **Success Metrics** - Time to POC, commits, user testing

## 🎯 Experiment Goals

### Quantitative Metrics

- [ ] Time from idea to deployed POC: < 24 hours
- [ ] Code commits: > 10 in first week
- [ ] User testing: > 5 people
- [ ] Iteration cycles: > 3 complete loops

### Qualitative Goals

- [ ] Demonstrates autonomous improvement
- [ ] Handles errors gracefully
- [ ] Produces useful output
- [ ] Evolves over time

## 💡 Alternative Product Ideas

Not sure if Quick Notes is the right choice? Here are alternatives considered:

1. **Loop Task Manager** - "Task manager that learns from how you work"
2. **Quick Polls/Surveys** - "Create and share polls in seconds"
3. **URL Shortener with Analytics** - "Short links that tell you everything"

See `progress.md` for detailed elevator pitches and analysis.

## 🛠️ Tech Stack

- **Frontend:** Plain HTML/CSS/JavaScript (no frameworks for simplicity)
- **Storage:** LocalStorage for offline-first MVP
- **Backend:** None needed for initial MVP
- **Runtime:** OpenCode CLI for autonomous operation
- **Container:** Docker/Podman for reproducible environments

## 📈 Next Steps

### Immediate (This Week)

- [ ] User testing with 3-5 people
- [ ] Add search and filter features
- [ ] Implement export/import functionality
- [ ] Deploy to static hosting (GitHub Pages)

### Short Term (This Month)

- [ ] Add tag system and categorization
- [ ] Implement keyboard shortcuts documentation
- [ ] Create browser extension
- [ ] Add sync backend design

### Long Term (Evolution)

- [ ] Real-time sync across devices
- [ ] Collaboration features
- [ ] API for third-party integrations
- [ ] Mobile app (React Native/Flutter)

## 🤝 Contributing

This is an autonomous experiment, but suggestions are welcome:

1. **Fork** the repository
2. **Create** a feature branch
3. **Implement** your improvement
4. **Test** with `./ralph.sh 1`
5. **Commit** your changes
6. **Submit** a pull request

## 📚 Documentation

- **[SETUP.md](docs/SETUP.md)** - Complete setup guide for Gastown and dependencies
- **[DOCKER_CHOICES.md](docs/DOCKER_CHOICES.md)** - Dockerfile decision matrix and examples
- **[progress.md](progress.md)** - Detailed experiment progress and metrics
- **[prompt.md](prompt.md)** - Core objectives and constraints

## 🎉 Success Stories

The loop has already demonstrated:

1. ✅ **Self-initialization** - Created complete project structure
2. ✅ **Documentation** - Generated comprehensive setup guides
3. ✅ **Product selection** - Chose Quick Notes as "Simple Choice"
4. ✅ **Implementation** - Built functional MVP in < 2 hours
5. ✅ **Autonomous operation** - Loop runs and commits without intervention
6. ✅ **Progress tracking** - Maintains detailed experiment log

## ⚠️ Known Limitations

- 🚧 Currently single-user (no collaboration)
- 🚧 LocalStorage only (no cloud sync yet)
- 🚧 Manual deployment (no CI/CD pipeline)
- 🚧 Limited testing (no automated tests)

These are planned improvements for future iterations!

## 📄 License

This is an experiment. Use, modify, and learn from it freely.

---

**Made with ⚡ by RalphLoop**
_Autonomous development, evolved._
