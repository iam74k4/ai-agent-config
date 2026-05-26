# .cursor 索引

言語: [English](README.md) | [日本語](README.ja.md)

`.cursor/` 配下のルール、ドキュメント、補助スクリプトへの入口です。

## ワークスペース

マルチルートワークスペースファイルは、リポジトリルートの `Cursor.code-workspace` にあります。含まれるフォルダーは、ルートの **`README.md` → Workspace** または **`README.ja.md` → ワークスペース** に記載されています。兄弟リポジトリを追加または削除するときは、両方を合わせて更新してください。

## エージェント

| パス | 目的 |
|------|------|
| `agents/README.md` / `agents/README.ja.md` | エージェント定義の配置場所と整理方法 |

## ドキュメント

| パス | 目的 |
|------|------|
| `docs/mcp.md` | MCP のセットアップ、有効なサーバー、トラブルシューティング |

## ルール

| パス | 目的 |
|------|------|
| `rules/README.md` / `rules/README.ja.md` | 共有ルールの索引 |
| `rules/git/git-rules.mdc` | Git ワークフロー、Conventional Commits、タグポリシー |
| `rules/docs/readme-rules.mdc` | README 構成、執筆ルール、Markdown 図のガイド |
| `rules/mcp/context7-rules.mdc` | Context7 を使うタイミングのルール |
| `rules/mcp/drawio-rules.mdc` | draw.io MCP 利用の補助ルール |
| `rules/mcp/github-rules.mdc` | GitHub MCP 利用の補助ルール |
| `rules/mcp/markitdown-rules.mdc` | MarkItDown MCP 利用の補助ルール |

## スクリプト

| パス | 目的 |
|------|------|
| `scripts/README.md` / `scripts/README.ja.md` | スクリプト索引と前提条件 |
| `scripts/drawio-mcp.sh` | draw.io MCP 起動前にクリーンアップするラッパー |
| `scripts/markitdown-mcp.sh` | `markitdown-mcp` をローカル venv 優先、なければ `PATH` から起動 |

## クイックスタート

1. ワークスペース全体の概要は、リポジトリルートの `README.md` または `README.ja.md` から確認します。
2. エージェント定義を追加する前に、`agents/README.md` または `agents/README.ja.md` を確認します。
3. MCP サーバーを設定または利用する前に、`docs/mcp.md` を読みます。
4. 共有ルールの入口として、`rules/README.md` または `rules/README.ja.md` を使います。
5. 補助スクリプトを使う前に、`scripts/README.md` または `scripts/README.ja.md` を確認します。
