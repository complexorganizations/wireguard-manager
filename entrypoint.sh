#!/bin/bash

# ساخت کلیدها
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key

SERVER_PRIV=$(cat server_private.key)
SERVER_PUB=$(cat server_public.key)
CLIENT_PRIV=$(cat client_private.key)
CLIENT_PUB=$(cat client_public.key)

SERVER_PORT=51820
SERVER_IP="10.0.0.1"
CLIENT_IP="10.0.0.2"

# فایل کانفیگ سرور
cat > wg0.conf <<EOF
[Interface]
PrivateKey = $SERVER_PRIV
Address = $SERVER_IP/24
ListenPort = $SERVER_PORT

[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = $CLIENT_IP/32
EOF

# فایل کانفیگ کلاینت
cat > client.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV
Address = $CLIENT_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB
Endpoint = YOUR_SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# تولید QR code
echo ""
echo "🔐 WireGuard Client Config:"
cat client.conf

echo ""
echo "📱 Scan this QR in your WireGuard app:"
qrencode -t ansiutf8 < client.conf