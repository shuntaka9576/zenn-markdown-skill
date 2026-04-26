## ローカル LLM をターミナルから叩いてみる

ollama を入れてみたのでメモ。

ollama のインストール

https://github.com/ollama/ollama/blob/main/README.md

TODO: インストール手順を後で書く

モデルを引っ張ってくる

```bash
ollama pull llama3.1
```

これで初回はモデルのダウンロードが走る。けっこうディスクを食うので注意。だいたい 4GB くらい。

ollama の API は OpenAI 互換のものも生えていて、curl から普通に叩ける。

```bash
curl http://localhost:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"llama3.1","messages":[{"role":"user","content":"hello"}]}'
```

レスポンスは OpenAI 形式。

参考のスライド。

https://speakerdeck.com/example/local-llm-intro

実際に動かしてる動画。

https://www.youtube.com/watch?v=dQw4w9WgXcQ

注意: GPU を持っていないマシンだと推論が CPU フォールバックになる。Mac は MPS で動くので、M シリーズなら実用的な速度が出る。Linux で CUDA がないと体感的にきつい。

Tips: モデルの保存先を変えたいときは `OLLAMA_MODELS` 環境変数で指定できる。デフォルトは `~/.ollama/models`。SSD の容量が厳しい場合は外付けにしておくと良い。

警告: ollama serve をパブリックなインターフェースに bind するときは認証を必ず入れること。素の ollama にはアクセス制御がないので、外向けに開けると誰でも叩けるエンドポイントになる。

おまけで、長めのデバッグ手順をメモしておく。

`OLLAMA_DEBUG=1` を付けて起動するとログが詳細化する。GPU メモリのアロケーション失敗、モデルのロード時間、推論ステップごとの token/sec などが見える。詰まったときはまずこれを見る。あとはシステムログにも `ollama` プロセスの stderr が流れているので、`journalctl -u ollama` (Linux) や Console.app (Mac) で追える。長時間ログを取りたいときは `OLLAMA_DEBUG=1 ollama serve 2>&1 | tee ollama.log` のようにしてファイルに落としておくと後で grep できる。

メモはここまで。
