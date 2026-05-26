# ルール

言語: [English](README.md) | [日本語](README.ja.md)

`.cursor/rules/` 配下にある共有ルールの索引です。

## ディレクトリ構成

| パス | 目的 |
|------|------|
| `git/` | Git ワークフロー、コミット、ブランチ、タグポリシー |
| `docs/` | README などのドキュメント編集ルール |
| `mcp/` | MCP 利用の補助ルール |

## 主なルール

| パス | 目的 |
|------|------|
| `git/git-rules.mdc` | Conventional Commits、main のみのワークフロー、SemVer タグポリシー |
| `docs/readme-rules.mdc` | README 構成、バッジ、見出し順、図のガイド |
| `mcp/context7-rules.mdc` | 最新のライブラリドキュメントを取得するときに Context7 を使う |
| `mcp/drawio-rules.mdc` | draw.io MCP で図を作成 / 編集するためのガイド |
| `mcp/github-rules.mdc` | GitHub MCP (issue、PR、検索、コメント) のガイド |
| `mcp/markitdown-rules.mdc` | MarkItDown MCP でドキュメントを Markdown に変換するためのガイド |

## 使い方

- 常時適用されるワークフロールールは `git/` を確認します。
- README やその他ドキュメントを編集するときは `docs/` を確認します。
- GitHub、Context7、draw.io、MarkItDown などの MCP ワークフローでは `mcp/` を確認します。詳細なセットアップは `../docs/mcp.md` にあります。

## 関連

- メイン索引: `../README.md` / `../README.ja.md`
- MCP ガイド: `../docs/mcp.md`
- 補助スクリプト: `../scripts/README.md` / `../scripts/README.ja.md`
