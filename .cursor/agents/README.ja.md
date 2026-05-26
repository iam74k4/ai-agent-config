# エージェント

言語: [English](README.md) | [日本語](README.ja.md)

`.cursor/agents/` は、ワークスペース固有のエージェント定義と関連ファイルを置く場所です。

## 目的

- プロジェクト固有のエージェント定義をここに追加します。
- ルールファイルだけでは表現しにくい、実行ロールに関する定義に使います。
- 参照するドキュメントや補助ファイルは、それを使うエージェントの近くに置きます。

## ガイドライン

- ロールごとにファイルまたはサブディレクトリを分けます。
- 名前だけで目的が分からないエージェントは作らないようにします。
- 永続的な振る舞いのルールは `../rules/README.md` または `../rules/README.ja.md` 経由で `rules/` に置き、エージェントファイルには実行時の意図を中心に書きます。
- MCP 固有の振る舞い (GitHub、Context7、draw.io、MarkItDown など) は、`../rules/mcp/` と `../docs/mcp.md` を参照します。
- エージェントが MCP やスクリプトに依存する場合は、`../docs/mcp.md` または `../scripts/README.md` / `../scripts/README.ja.md` への参照を含めます。

## 関連

- メイン索引: `../README.md` / `../README.ja.md`
- MCP ガイド: `../docs/mcp.md`
- 共有ルール: `../rules/README.md` / `../rules/README.ja.md`
- 補助スクリプト: `../scripts/README.md` / `../scripts/README.ja.md`
