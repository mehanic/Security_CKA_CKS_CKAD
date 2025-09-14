
#Shared Mount 
install -D -m 0755 /dev/stderr /etc/local.d/10-mount.start 2<<-EOF
	#!/bin/sh
	mount --make-rshared /
EOF
rc-update add local default

#Bash base64 padding
cat my_jwt_token.txt \
		| awk -F'.' '{l=length($2)+2; print substr($2"==",1,l-l%4)}' \
		| base64 -d | jq -r '.exp' \
		| xargs test "$(date +%s)" -lt


decode() {
    awk -vstr="${1}" 'BEGIN {l=length(str)+2; print substr(str"==",1,l-l%4)}' \
        | base64 -d \
        | { cat; echo; }
}

decode "bGlnaHQgd29yay4"
decode "bGlnaHQgd29yaw"
decode "bGlnaHQgd29y"
decode "bGlnaHQgd28"
decode "bGlnaHQgdw"


#install custom certificate with mkcert
cp {ca_certificate,rootCA}.pem
CAROOT="$(pwd)" mkcert -install


#KVM with Docker bridge
qemu-system-x86_64 ... \
	-netdev "bridge,id=user.1,br=docker0" \
	-device "virtio-net,netdev=user.1"


#Kvm Hello World
set -euo pipefail

# --- Config ---
DISK_BASE="base.qcow2"
DISK_OVERLAY="hdd.qcow2"
DISK_SIZE="10G"
ISO_IMAGE="${1:-debian.iso}"  # pass ISO as arg, e.g. ./kvm.sh debian.iso
RAM="4G"
CPUS=4

# --- Step 1: Create base image if not exists ---
if [[ ! -f "$DISK_BASE" ]]; then
  echo "[*] Creating base image $DISK_BASE ($DISK_SIZE)..."
  qemu-img create -f qcow2 "$DISK_BASE" "$DISK_SIZE"
fi

# --- Step 2: Always create a fresh overlay ---
echo "[*] Resetting overlay image $DISK_OVERLAY..."
qemu-img create -F qcow2 -f qcow2 -b "$DISK_BASE" "$DISK_OVERLAY"

# --- Step 3: Start VM ---
echo "[*] Starting VM with KVM acceleration..."
qemu-system-x86_64 \
  -m "$RAM" \
  -smp "$CPUS" \
  -cpu host \
  -accel kvm \
  -hda "$DISK_OVERLAY" \
  -boot once=d \
  -cdrom "$ISO_IMAGE" \
  -monitor "unix:monitor.sock,server=on,wait=off" \
  -serial "chardev:serial0" \
  -chardev "socket,id=serial0,path=console.sock,server=on,wait=off" \
  -netdev "user,id=user.1,hostfwd=tcp::2222-:22" \
  -device "virtio-net,netdev=user.1" \
  -display none



#Socat, Telnet and Unix sockets

#Connect to remote port:
echo | socat - tcp:foo.bar:22
#Connect to remote virtual terminal over TCP:

socat -,rawer,escape=0x1d tcp:foo.bar:23
#Connect to a local virtual terminal over a Unix socket:

socat file:`tty`,rawer,escape=0x1d unix-connect:console.sock
#The option file:`tty` is equivalent to - here. The following command will have the same behavior:

socat -,rawer,escape=0x1d unix-connect:console.sock
#Issue an http request:

echo -e "GET / HTTP/1.1\nHost: www.example.com\n" | socat - tcp:www.example.com:80
#Issue an https request:

echo -e "GET / HTTP/1.1\nHost:github.com\n" | socat - openssl:github.com:443
#During my investigation around socat I noticed a weird potential bug. It seems that https connection is broken when connecting to a website with a wildcard certificate. You can check if that’s the case by running:

echo | openssl s_client -connect google.com:443 2> /dev/null | grep -i subject
#When running socat against this domain using https you will get the following error:

#socat[26639] E SSL_connect(): error:1416F086:SSL routines:tls_process_server_certificate:certificate verify failed
#I managed to make it work by piping socat to cat, I have no idea why this happen or the reason why the piping fixes it (I discovered this out of pure luck). So the final working command will be:

echo -e "GET / HTTP/1.1\nHost:google.com\n" | socat - openssl:google.com:443  | cat


#Terraform retrieve sensible data

terraform show -json | \
	jq '.values.root_module.resources[] | select(.address == "aws_iam_access_key.foo") | .values'

#The wild kubectl logs issue 
alias klog='kubectl logs --tail=-1 --prefix --timestamps'



#WireGuard VPN

uname -r

apk add wireguard-$(uname -r)

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

cat > /etc/local.d/60-forward.start <<'EOF'
#!/bin/sh
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
EOF
chmod +x /etc/local.d/60-forward.start
rc-update add local default

iptables -P FORWARD ACCEPT
/etc/init.d/iptables save
rc-update add iptables

ip6tables -P FORWARD ACCEPT
/etc/init.d/ip6tables save
rc-update add ip6tables

#----

FROM alpine:3.12

RUN apk add --no-cache wireguard-tools ip6tables
COPY server.sh /usr/local/bin/wireguard
EXPOSE 5555
CMD ["wireguard"]

#----

cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(wg genkey)
Address = 10.0.0.1/24, fd47:d1a9:8d26:c99b::/64
ListenPort = 5555
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; \
         iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; \
         ip6tables -A FORWARD -i wg0 -j ACCEPT; \
         ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; \
           iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; \
           ip6tables -D FORWARD -i wg0 -j ACCEPT; \
           ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true
EOF

wg-quick up wg0
watch wg

#----

docker build -t wireguard .

docker run --rm --detach --name wireguard \
  --cap-add=NET_ADMIN --cap-add=SYS_MODULE \
  --network=host --volume /lib/modules:/lib/modules \
  wireguard


#----

public="${1}"
private="$(wg genkey)"

cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = ${private}
Address = 10.0.0.2/24, fd47:d1a9:8d26:c99b::1/64
DNS = 8.8.8.8

[Peer]
PublicKey = ${public}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = <remote-host>:5555
EOF

echo "${private}" | wg pubkey

#-----

ssh <remote-host> docker exec -i wireguard wg show wg0 public-key \
  | sudo ./setup.sh \
  | xargs -rI{} ssh <remote-host> docker exec -i wireguard \
      wg set wg0 peer {} allowed-ips 10.0.0.2/32 allowed-ips fd47:d1a9:8d26:c99b::1/128

sudo wg-quick up wg0

docker logs -f wireguard


ping 10.0.0.1
curl ifconfig.me   # показатu IP сервер
#---------------------------------


#gopass
set -e

# -------------------------------
# Настройки
# -------------------------------
STORE_NAME="foo"
STORE_PATH="$HOME/.local/share/password-store/$STORE_NAME"
GIT_REMOTE="git@rulz.xyz:keys.git"
DIRENV_FILE="$PWD/.envrc"

# -------------------------------
# 1. Установка gopass (если не установлен)
# -------------------------------
if ! command -v gopass >/dev/null 2>&1; then
    echo "Installing gopass..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y gopass gnupg git
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add gopass gnupg git
    else
        echo "Please install gopass, gnupg and git manually"
        exit 1
    fi
fi

# -------------------------------
# 2. Инициализация хранилища gopass
# -------------------------------
if [ ! -d "$STORE_PATH" ]; then
    echo "Initializing gopass store..."
    gopass init --path "$STORE_PATH" --store "$STORE_NAME"
else
    echo "Store already exists at $STORE_PATH"
fi

# -------------------------------
# 3. Подключение Git
# -------------------------------
cd "$STORE_PATH"
if ! git remote | grep origin >/dev/null 2>&1; then
    echo "Adding Git remote..."
    gopass git remote add --store "$STORE_NAME" "$GIT_REMOTE"
    git push origin HEAD:master
else
    echo "Git remote already configured"
fi
cd -

# -------------------------------
# 4. Создание примера переменной для direnv
# -------------------------------
if [ ! -f "$DIRENV_FILE" ]; then
    echo "Creating .envrc file for direnv..."
    cat << EOF > "$DIRENV_FILE"
# Auto-generated by gopass setup script
export EXAMPLE_SECRET=\$(gopass show $STORE_NAME/example)
EOF
    echo "Run 'direnv allow' to load the environment variables"
else
    echo ".envrc already exists"
fi

echo "✅ gopass setup completed!"

