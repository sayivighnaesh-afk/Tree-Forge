# TreeForge — Student Index Recovery System

TreeForge is a browser-based application for the **Registrar's Fragmented Student Index** problem. Given up to 100 small internally valid Binary Search Tree (BST) fragments (1 to 3 nodes each, distinct root IDs), TreeForge connects fragments strictly where an existing leaf has the same ID as another fragment's root, merges every fragment exactly once without duplicating the shared ID, validates global BST ordering across all ancestor bounds, and renders the recovered tree in SVG—or reports a structured `IMPOSSIBLE` explanation.

---

## Architecture & Repository Layout

```text
├── backend/
│   ├── app.py                  # Flask app, JSON API routes, and static frontend serving
│   ├── models.py               # Pure-Python Node, Fragment, Connection, RecoveryResult models
│   ├── parser.py               # Request validation and JSON-to-Fragment parsing (max 100)
│   ├── fragment_validator.py   # Per-fragment shape, internal BST, and distinct-root validation
│   ├── recovery.py             # Leaf-to-root matching, root selection, cycle/ambiguity checks, merge
│   ├── bst_validator.py        # Recursive exclusive (low, high) global BST validation
│   └── traversal.py            # Inorder traversal and nested-dict tree serialization
├── frontend/
│   ├── index.html              # Responsive dark/noir developer-tool UI
│   ├── css/style.css           # High-contrast dark theme with teal/emerald status accents
│   └── js/
│       ├── api.js              # Fetch client for /api/health, /api/examples, /api/recover
│       ├── builder.js          # Structured table editor, live mini-SVG previews, inline validation
│       ├── tree-view.js        # Pure SVG tree layout and zoomable renderer with L/R edge labels
│       └── app.js              # Session state, sample loader, playback controls, error display
├── tests/
│   ├── test_parser.py
│   ├── test_fragment_validator.py
│   ├── test_bst_validator.py
│   ├── test_recovery.py
│   └── test_api.py
├── examples/
│   └── examples.json           # Canonical valid & impossible sample cases
├── requirements.txt
├── Procfile                    # Production Gunicorn command
└── render.yaml                 # Render deployment blueprint
```

The recovery algorithm (`backend/models.py`, `parser.py`, `fragment_validator.py`, `recovery.py`, `bst_validator.py`, `traversal.py`) is **100% pure Python**, completely independent of Flask and the frontend.

---

## Local Setup & Run Instructions

### Windows (PowerShell)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m backend.app
```

### macOS / Linux
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m backend.app
```

Open **http://127.0.0.1:5000** in your browser.

### Run the Test Suite
```powershell
.\.venv\Scripts\python.exe -m pytest -v
```

---

## Algorithm Complexity & Assumptions

Let $N$ be the number of fragments ($1 \le N \le 100$) and $V \le 3N$ be the total number of node slots:
- **Parsing & Per-Fragment Validation:** $O(N)$ time, $O(N)$ space.
- **Root-ID Lookup & Leaf-to-Root Matching:** $O(N)$ time using a hash map from `root.id` to `Fragment`.
- **Ambiguity, Root Selection & Recursive Merge:** $O(N)$ time, $O(N)$ space (tracks `visited` and `active_stack` to prevent cycles and repeated attachment).
- **Global BST Validation & Inorder Traversal:** $O(V) = O(N)$ time, $O(H)$ recursion stack where $H \le N + 1$.

### Explicit Policies
- **Shared Attachment ID:** When a fragment root matches a leaf placeholder, the placeholder is replaced by the fragment root so the shared ID appears **once** in the final tree.
- **Ambiguous Matches:** If a fragment root ID matches more than one eligible leaf position across the input, recovery fails conservatively with `AMBIGUOUS_MATCH` rather than guessing.
- **Strict BST Ordering:** Exclusive ancestor bounds (`low < node.id < high`) enforce strictly increasing inorder traversal and forbid duplicate node IDs anywhere in the final tree.

---

## API Contract

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/api/health` | `GET` | Service health check (`status: "ok"`) |
| `/api/examples` | `GET` | Built-in valid and impossible sample cases |
| `/api/validate-fragments` | `POST` | Validate request shape and per-fragment rules |
| `/api/recover` | `POST` | Run full recovery pipeline and return tree, inorder traversal, trace, checks, and structured errors |

### Example Request (`POST /api/recover`)
```json
{
  "fragments": [
    {"fragment_id": "T1", "root": 2, "left": 1, "right": null},
    {"fragment_id": "T2", "root": 3, "left": 2, "right": 5},
    {"fragment_id": "T3", "root": 5, "left": 4, "right": null}
  ]
}
```

### Example Response (`200 OK`)
```json
{
  "success": true,
  "root_id": 3,
  "tree": {
    "id": 3,
    "left": {"id": 2, "left": {"id": 1, "left": null, "right": null}, "right": null},
    "right": {"id": 5, "left": {"id": 4, "left": null, "right": null}, "right": null}
  },
  "inorder": [1, 2, 3, 4, 5],
  "connections": [
    {"from_fragment": "T2", "to_fragment": "T1", "matched_id": 2, "side": "left"},
    {"from_fragment": "T2", "to_fragment": "T3", "matched_id": 5, "side": "right"}
  ],
  "steps": [...],
  "checks": {
    "fragments_valid": true,
    "distinct_roots": true,
    "single_overall_root": true,
    "all_fragments_used": true,
    "no_cycles_or_ambiguity": true,
    "global_bst_valid": true
  },
  "errors": []
}
```

---

## 2–3 Minute Judging Demo Script

1. **Open TreeForge** at `http://127.0.0.1:5000` (or your Render deployment URL) and point out the live `API Online` status pill.
2. **Show the Blueprint Example** pre-loaded in the Fragment Builder (`T1=[2,1,null]`, `T2=[3,2,5]`, `T3=[5,4,null]`) along with the live mini-SVG previews.
3. **Click `Recover Tree`**:
   - Show the `RECOVERED` status badge, **Final Root: `3`**, and **Inorder Traversal: `1, 2, 3, 4, 5`**.
   - Point out in the SVG tree that **node `4` is the `L` (left) child of node `5`** and shared IDs `2` and `5` are not duplicated.
   - Click **Play** in the Recovery Trace bar to animate `T2 → T1 @ 2 (left)` and `T2 → T3 @ 5 (right)`.
4. **Load an Impossible Case** from the preset dropdown (e.g., **Global BST Ordering Conflict** or **Disconnected Fragments**) and click `Recover Tree`:
   - Highlight the structured `IMPOSSIBLE` banner, the exact failing check pill (`Global BST Ordering` or `Single Overall Root`), and the clear ancestor-bound / disconnected explanation.
5. **Close** by noting that all recovery and validation logic runs in pure Python with full `pytest` coverage up to the 100-fragment limit, while the UI serves as a transparent visual inspector.

---

## Deployment (Render)

1. Push this repository to GitHub.
2. Create a new **Blueprint** or **Web Service** on Render pointing to the repo (`render.yaml` is pre-configured with `pip install -r requirements.txt`, `gunicorn backend.app:app --bind 0.0.0.0:$PORT`, `FLASK_DEBUG=0`, and `/api/health`).
3. Verify `GET /api/health` and run both the Blueprint Example and at least two impossible cases in the browser.
