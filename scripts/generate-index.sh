#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Recursively generate an index.html in every folder of public/
# -------------------------------------------------------------------

ROOT="public"

if [[ ! -d "$ROOT" ]]; then
  echo "Error: Directory '$ROOT/' does not exist."
  exit 1
fi

# Loop over every directory (including ROOT itself)
# `find "$ROOT" -type d` gives a list like:
#   public
#   public/assets
#   public/docs
#   public/docs/examples
#   …

find "$ROOT" -type d | while read -r DIR; do
  # Start writing to DIR/index.html (overwrite)
  cat > "$DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>OriginUi Repository</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined" rel="stylesheet" />
<style>
  * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
  }
  body {
      font-family: 'Inter', sans-serif;
      background-color: #212121; /* Gray 900 */
      color: #f5f5f5;            /* Gray 100 */
      line-height: 1.6;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
  }
  a {
      color: #90caf9; /* Blue 200 */
      text-decoration: none;
      transition: all 0.2s ease-in-out;
  }
  a:hover {
      text-decoration: underline;
  }

  /* ─── Header Bar ─── */
  header {
      background: transparent; /* slightly darker tone */
      color: #f5f5f5;
      padding: 1rem 2rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
  }
  header .logo {
      font-size: 1.5rem;
      font-weight: 600;
      color: #ffffff;
      text-decoration: none;
  }
  header nav a {
      color: #e0e0e0;
      font-size: 0.95rem;
      margin-left: 1rem;
  }

  main {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
  }

  .up {
      margin-bottom: 1rem;
      display: inline-block;
  }

  /* ─── Material Symbols ─── */
  .material-symbols-outlined {
      font-variation-settings:
          'FILL' 0,
          'wght' 400,
          'GRAD' 0,
          'opsz' 24;
      vertical-align: middle;
      margin-right: 0.4rem;
      font-size: 20px;
  }
</style>
</head>
<body>
    <!-- ─── Header Bar ─── -->
  <header>
    <a href="/" class="logo">OriginUi Repo</a>
    <nav>
        <a href="/"><span class="material-symbols-outlined">home</span>Home</a>
    </nav>
  </header>
  <main>
    <div class="content">
        <h1>Browser
EOF

  # If DIR is not exactly "public/", show a link “[↗ Parent]”
  if [[ "$DIR" != "$ROOT" ]]; then
    # A single "../" will always move you up one level
    echo "  <p class=\"up\"><a href=\"../\"><span class="material-symbols-outlined">arrow_back</span>Parent</a></p>" >> "$DIR/index.html"
  fi

  # Close the <h1> tag started above; we can show the path
  # (we want to show something like "public/docs/examples" → "/docs/examples/")
  dir_url="${DIR#public}"   # e.g. "/docs/examples"
  if [[ -z "$dir_url" ]]; then
    dir_url="/"
  fi
  echo "  </h1>" >> "$DIR/index.html"
  echo "  <ul>"   >> "$DIR/index.html"

  # List everything directly under $DIR, except its own index.html
  for entry in "$DIR"/*; do
    name="$(basename "$entry")"
    if [[ "$name" == "index.html" ]]; then
      continue
    fi

    # Determine the href. If $entry is a directory, add trailing slash.
    if [[ -d "$entry" ]]; then
      echo "    <li>[DIR] <a href=\"./$name/\">$name/</a></li>" >> "$DIR/index.html"
    else
      echo "    <li>[FILE] <a href=\"./$name\">$name</a></li>" >> "$DIR/index.html"
    fi
  done

  echo "    </ul>" >> "$DIR/index.html"
  echo "  </div>" >> "$DIR/index.html"
  echo " </main>" >> "$DIR/index.html"
  echo "</body>"  >> "$DIR/index.html"
  echo "</html>"  >> "$DIR/index.html"

  echo "→ Generated index at $DIR/index.html"
done

