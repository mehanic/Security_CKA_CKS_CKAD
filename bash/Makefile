PREFIX ?= /usr/local
SYSTEMD_USER_DIR ?= $(HOME)/.config/systemd/user
AGE_KEY_FILE ?= $(HOME)/.config/age/keys.txt

all: install-deps setup-age init-gopass enable-janus

## 1. Установка зависимостей
install-deps:
	@echo ">>> Installing gopass, gopass-age, janus"
	go install github.com/gopasspw/gopass@latest
	go install github.com/gopasspw/gopass-age@latest
	git clone https://github.com/IxDay/janus.git /tmp/janus && \
		cd /tmp/janus && make && PREFIX=$(PREFIX) make install

## 2. Генерация age-ключа (если нет)
setup-age:
	@if [ ! -f "$(AGE_KEY_FILE)" ]; then \
		echo ">>> Generating age key at $(AGE_KEY_FILE)"; \
		mkdir -p $$(dirname $(AGE_KEY_FILE)); \
		age-keygen -o $(AGE_KEY_FILE); \
	else \
		echo ">>> Age key already exists at $(AGE_KEY_FILE)"; \
	fi

## 3. Инициализация gopass store (age)
init-gopass:
	@echo ">>> Initializing gopass with age backend"
	gopass init --crypto=age --rcpt-file $(AGE_KEY_FILE) || true

## 4. Установка и запуск systemd unit
enable-janus:
	@echo ">>> Enabling Janus systemd unit"
	mkdir -p $(SYSTEMD_USER_DIR)
	cp systemd/ssh-agent.service $(SYSTEMD_USER_DIR)/
	systemctl --user daemon-reload
	systemctl --user enable --now ssh-agent.service

status:
	systemctl --user status ssh-agent.service

logs:
	journalctl --user -fu ssh-agent.service

