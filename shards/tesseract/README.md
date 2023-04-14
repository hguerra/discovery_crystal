## Install

```
apt install -y -qq make lsb-release curl gnupg gnupg1 gnupg2 apt-transport-https tzdata gcc pkg-config libssl-dev libxml2-dev libyaml-dev libgmp-dev libpcre3-dev libpcre2-dev libevent-dev libz-dev build-essential llvm-15 lld-15 libedit-dev gdb libffi-dev

echo "deb https://notesalexp.org/tesseract-ocr-dev/$(lsb_release -cs)/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/notesalexp.list

curl -fsSL "https://notesalexp.org/debian/alexp_key.asc" | apt-key add -

cat "/etc/apt/sources.list.d/notesalexp.list"

apt-get update -qq

apt-get install -y -qq tesseract-ocr libtesseract-dev libleptonica-dev


# vim ~/.zshrc
# export TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata/
# source ~/.zshrc

apt-get install -y -qq tesseract-ocr-eng tesseract-ocr-por tesseract-ocr-jpn
```
