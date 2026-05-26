# スクリプト

言語: [English](README.md) | [日本語](README.ja.md)

`.cursor/scripts/` 配下にある補助スクリプトの索引です。

## 前提条件

- このディレクトリのスクリプトは、Cursor から直接参照される場合があります。
- `drawio-mcp.sh` は `bash`、`pkill`、`lsof`、`ps` を使います。
- Windows では、WSL や Git Bash など Unix 風コマンドが使える環境を前提とします。
- `markitdown-mcp.sh` は `bash` を使い、`.cursor/venv-markitdown` を利用できます。
- `markitdown-mcp.ps1` は PowerShell とローカルの `.venv-markitdown` 仮想環境を使います。

## 利用可能なスクリプト

| スクリプト | 目的 |
|------------|------|
| `drawio-mcp.sh` | ポート競合を避けるため、draw.io MCP 起動前に既存プロセスを停止します |
| `markitdown-mcp.sh` | `.cursor/venv-markitdown` があればそこから、なければ `PATH` から `markitdown-mcp` を実行します (`MARKITDOWN_MCP_VENV` で venv パスを上書き可能) |
| `markitdown-mcp.ps1` | ローカル Python 仮想環境から MarkItDown MCP サーバーを起動します |

## 関連ドキュメント

- メインの `.cursor` 索引は `../README.md` または `../README.ja.md` を参照してください。
- MCP のセットアップとサーバー詳細は `../docs/mcp.md` を参照してください。
- draw.io 固有のルールは `../rules/mcp/drawio-rules.mdc` を参照してください。
- MarkItDown MCP の使い方は `../rules/mcp/markitdown-rules.mdc` を参照してください。
