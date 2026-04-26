---
title: "GitHub Actions で OIDC を使った AWS デプロイの落とし穴"
emoji: "🐳"
type: "tech"
topics: ["githubactions", "aws", "oidc"]
published: false
---

## はじめに

GitHub Actions から AWS にデプロイするとき、長期の IAM アクセスキーを使い続けるのは避けたい。OIDC を使った一時クレデンシャルに移行する手順をまとめる。

> [!NOTE]
> この記事は AWS アカウントの管理権限を持っている読者向け。IAM ロールの作成や信頼ポリシーの編集権限が必要になる。

## 全体像

GitHub Actions のワークフロー実行ごとに、GitHub が短命の OIDC トークンを発行し、AWS の IAM ロールが `sts:AssumeRoleWithWebIdentity` で一時クレデンシャルを払い出す、という流れになる。

参考: 公式ドキュメントは下記。

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## IAM 側のセットアップ

1. ID プロバイダ `token.actions.githubusercontent.com` を作成
2. IAM ロールを作成し、信頼ポリシーで対象リポジトリ（`repo:<owner>/<repo>:*` など）を絞る

> [!IMPORTANT]
> `sub` クレームの絞り込みは慎重にやる。`repo:<owner>/<repo>:*` のままだと、対象リポジトリの **どのブランチ・どのワークフロー** からでもこのロールを引き受けられてしまう。本番デプロイ用のロールは `repo:<owner>/<repo>:ref:refs/heads/main` のように環境やブランチで絞ること。

## ワークフロー側

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-deploy
          aws-region: ap-northeast-1
```

`id-token: write` を忘れると OIDC トークンが発行されない。

> [!TIP]
> ローカルで `act` を使ってこのワークフローを試す場合は OIDC が動かない。`act` 用には別途長期キーで動かすか、ローカルでの実行はスキップするフラグを入れておくと開発中に詰まらない。

## ハマりどころ

> [!WARNING]
> 信頼ポリシーの `sub` を緩いままで本番運用に入ると、フォークリポジトリのプルリクエスト経由で本番ロールが引き受けられてしまうリスクがある。少なくとも本番デプロイ用のロールはブランチか environment で必ず絞ること。

> [!CAUTION]
> 既存の長期 IAM アクセスキーをすぐ削除しないこと。OIDC への移行が完了し、数日間ワークフローが安定して動いていることを確認してから削除する。先にキーを消すと、ロールバック手段がなくなる。

## まとめ

OIDC を入れるとキーローテーションの手間がなくなり、漏洩時の被害も限定的になる。最初の信頼ポリシーだけは丁寧に書こう。
