#!/usr/bin/env bash
# практика 1, самостоятельная часть, вариант 01

PREFIX=kovalenko-01
ZONE=ru-central1-d
CIDR=10.12.1.0/24
DISK=15
PORT=8003
IMAGE=debian-12

echo "поднимаю стенд $PREFIX в зоне $ZONE"

# сеть
yc vpc network create --name "$PREFIX-net"

# подсеть
yc vpc subnet create \
  --name "$PREFIX-subnet" \
  --network-name "$PREFIX-net" \
  --zone "$ZONE" \
  --range "$CIDR"

# группа безопасности: разрешить ssh и порт приложения
SG=$(yc vpc network get "$PREFIX-net" --format json | jq -r .default_security_group_id)
yc vpc security-group update-rules "$SG" \
  --add-rule "description=ssh,direction=ingress,protocol=tcp,port=22,v4-cidrs=[0.0.0.0/0]" \
  --add-rule "description=app,direction=ingress,protocol=tcp,port=$PORT,v4-cidrs=[0.0.0.0/0]"

# две машины
for n in 1 2; do
  yc compute instance create \
    --name "$PREFIX-app-$n" \
    --zone "$ZONE" \
    --platform standard-v3 \
    --cores=2 \
    --core-fraction=20 \
    --memory=2 \
    --preemptible \
    --create-boot-disk image-folder-id=standard-images,image-family=$IMAGE,type=network-hdd,size=$DISK \
    --network-interface subnet-name="$PREFIX-subnet",nat-ip-version=ipv4 \
    --hostname "$PREFIX-app-$n" \
    --ssh-key ~/.ssh/id_ed25519.pub \
    --labels created-by=cli
done

# показать адреса
echo
echo "машины подняты, публичные адреса:"
for n in 1 2; do
  IP=$(yc compute instance get "$PREFIX-app-$n" --format json \
    | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')
  echo "  $PREFIX-app-$n  ->  $IP"
done

echo
echo "дальше по ssh на каждую машину:"
echo "  sudo apt update && sudo apt install -y nginx"
echo "  настроить nginx на порт $PORT и слово labwork"
