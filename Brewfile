tap "hashicorp/tap"

# GitHub command-line tool
brew "gh"
# Open source relational database management system
brew "postgresql@18"
# Open-source, cross-platform JavaScript runtime environment
brew "node"
# Development kit for the Java programming language
brew "openjdk@21"
# Ruby version manager
brew "rbenv"
# JavaScript package manager
brew "yarn"
# Tool to build, change, and version infrastructure
brew "hashicorp/tap/terraform"
# Agent multiplexer that lives in your terminal
brew "herdr"

# Terminal-based AI coding assistant
cask "claude-code"
# Terminal emulator that uses platform-native UI and GPU acceleration
cask "ghostty"

# ============================================================================
# VS Code 拡張機能
#
# 【重要】brew bundle は「そのとき有効になっている Profile」に拡張を入れる。
# 2026-09-02 以降、拡張の有効・無効は Profile で振り分ける構成になっているため、
# PC 移行時は必ず Default Profile を開いた状態で brew bundle を実行し、
# そのあと Profile 側に振り分ける（Profile の構成は業務用の private リポジトリ側で管理）。
#
# ここは「マシンに入れておく拡張の全集合」を表す。
# どの Profile でどれを有効にするかは Brewfile では表現できない。
#
# brew bundle dump --vscode --force で作り直すと、
# このコメントごと消えるうえ Default Profile の内容しか書き出されない点に注意。
# ============================================================================

# --- 全 Profile 共通（Apply Extension to all Profiles を付けるもの）---
vscode "anthropic.claude-code"
vscode "eamodio.gitlens"
vscode "esbenp.prettier-vscode"
vscode "hediet.vscode-drawio"
vscode "ionutvmi.path-autocomplete"
vscode "ms-ceintl.vscode-language-pack-ja"
vscode "oderwat.indent-rainbow"
vscode "pkief.material-icon-theme"
vscode "qwtel.sqlite-viewer"
vscode "repreng.csv"
vscode "shd101wyy.markdown-preview-enhanced"
vscode "streetsidesoftware.code-spell-checker"
vscode "yzhang.markdown-all-in-one"

# --- Profile「Ruby 3.x」(新しい Ruby のプロジェクト用)---
vscode "shopify.ruby-lsp"

# --- Profile「Ruby 2.5」(古い Ruby のプロジェクト用)---
# ruby-lsp が動かない世代向け。gem 側の実行環境は業務用の private リポジトリで管理
vscode "castwide.solargraph"
vscode "misogi.ruby-rubocop"

# --- Profile「Ruby 3.x」と「Ruby 2.5」の両方 ---
vscode "hridoy.rails-snippets"
vscode "kaiwood.endwise"

# --- Ruby 2.5(ERB) と フロントエンド の両方 ---
vscode "ecmel.vscode-html-css"
vscode "formulahendry.auto-rename-tag"

# --- フロントエンド（Default Profile）---
vscode "ms-vscode.live-server"

# --- Profile「Infra」---
vscode "hashicorp.terraform"

# --- コード系 Profile ---
vscode "ms-vsliveshare.vsliveshare"

# mhutchie.git-graph は 2026-09-02 に削除した（eamodio.gitlens の
# Commit Graph で用途が重複していたため）
