# IP-Monitor
家のネットワーク内に立ってるsshサーバーとかそういうのに外からルーターのNAT越しにアクセスしたい。

固定IPアドレスも契約してないし、DDNSも面倒だし、VPNはもっとめんどくさい。

そういう時に、 振られてるグローバルIPアドレスを監視して変更があったらdiscordに通知してくれるやつ。

アクセスしたい計算機内で動かす想定。

## How to Use
```
git clone git@github.com:mznh/ip-monitor.git
cp env_sample .env
vim .env
mise trust
ruby ip_monitor.rb
```
