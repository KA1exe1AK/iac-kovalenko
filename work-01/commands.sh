# команды по практике 1, вариант 01, префикс kovalenko-01

# сервисный аккаунт
yc iam service-account create --name kovalenko-01-sa
yc resource-manager folder add-access-binding $(yc config get folder-id) \
  --role editor --subject serviceAccount:$(yc iam service-account get --name kovalenko-01-sa --format json | jq -r .id)
mkdir -p ~/.yc-keys
yc iam key create --service-account-name kovalenko-01-sa --output ~/.yc-keys/kovalenko-01-key.json

# сеть и подсеть
yc vpc network create --name kovalenko-01-net
yc vpc subnet create --name kovalenko-01-subnet --network-name kovalenko-01-net --zone ru-central1-a --range 10.11.1.0/24

# вторая подсеть, потому что в ru-central1-a нерабочие публичные адреса
yc vpc subnet create --name kovalenko-01-subnet-d --network-name kovalenko-01-net --zone ru-central1-d --range 10.12.1.0/24

# правило ssh в группе безопасности
yc vpc security-group update-rules enppdqaqvb26ft1978pb \
  --add-rule "description=ssh,direction=ingress,protocol=tcp,port=22,v4-cidrs=[0.0.0.0/0]"

# машина командой
yc compute instance create \
  --name kovalenko-01-web-1 \
  --zone ru-central1-d \
  --platform standard-v3 \
  --cores=2 \
  --core-fraction=20 \
  --memory=2 \
  --preemptible \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2404-lts,type=network-hdd,size=15 \
  --network-interface subnet-name=kovalenko-01-subnet-d,nat-ip-version=ipv4 \
  --hostname kovalenko-01-web-1 \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --labels created-by=cli

# отвязать и заново привязать публичный адрес (адрес попался нерабочий)
# делал через консоль, вручную

# только остановленные машины
yc compute instance list --format json | jq -r '.[] | select(.status != "RUNNING") | .name'

# уборка, порядок важен
yc compute instance delete kovalenko-01-web-1
yc compute instance delete kovalenko-01-web-manual
yc vpc subnet delete kovalenko-01-subnet-d
yc vpc subnet delete kovalenko-01-subnet
yc vpc network delete kovalenko-01-net
