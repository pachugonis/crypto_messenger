# Инструкция по развертыванию Vorthex на VPS Ubuntu 24

> **Примечание:** Репозиторий называется `crypto_messenger`, но приложение называется **Vorthex**. Работайте из папки `/var/www/vorthex` после клонирования.

## Требования

- VPS с Ubuntu 24.04 LTS
- Минимум 2GB RAM
- Доменное имя (опционально, для SSL)
- Root или sudo доступ

## 1. Подготовка сервера

### 1.1 Обновление системы

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.2 Установка зависимостей

```bash
# Установка базовых пакетов
sudo apt install -y curl git build-essential libssl-dev zlib1g-dev \
  libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev \
  libpq-dev nodejs npm

# Установка PostgreSQL
sudo apt install -y postgresql postgresql-contrib libpq-dev

# Установка Redis
sudo apt install -y redis-server
```

### 1.3 Установка Ruby 3.3.6

```bash
# Установка rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Установка ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Установка Ruby 3.3.6
rbenv install 3.3.6
rbenv global 3.3.6

# Проверка
ruby -v
```

### 1.4 Установка Bundler

```bash
gem install bundler
```

## 2. Настройка базы данных PostgreSQL

### 2.1 Создание пользователя и базы данных

```bash
# Войти в PostgreSQL
sudo -u postgres psql

# Создать пользователя
CREATE USER vorthex WITH PASSWORD 'your_secure_password';

# Создать базу данных
CREATE DATABASE vorthex_production OWNER vorthex;

# Выдать права
GRANT ALL PRIVILEGES ON DATABASE vorthex_production TO vorthex;

# Выход
\q
```

## 3. Клонирование и настройка приложения

### 3.1 Клонирование репозитория

```bash
cd /var/www
sudo mkdir -p vorthex
sudo chown $USER:$USER vorthex
cd vorthex

git clone https://github.com/pachugonis/crypto_messenger.git .
```

### 3.2 Установка зависимостей

```bash
bundle install --without development test
```

### 3.3 Настройка переменных окружения

Создайте файл `.env.production`:

```bash
nano .env.production
```

Добавьте следующие переменные:

```env
RAILS_ENV=production
DATABASE_URL=postgresql://vorthex:your_secure_password@localhost/vorthex_production
REDIS_URL=redis://localhost:6379/0

# Сгенерируйте секретные ключи командой: bin/rails secret
SECRET_KEY_BASE=your_secret_key_base
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=your_encryption_primary_key
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=your_encryption_deterministic_key
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=your_encryption_key_derivation_salt

# Настройки Action Cable
CABLE_URL=wss://yourdomain.com/cable
ALLOWED_REQUEST_ORIGINS=https://yourdomain.com

# SMTP настройки (для восстановления пароля)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USER_NAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

### 3.4 Генерация секретных ключей

```bash
# Генерация SECRET_KEY_BASE
bin/rails secret

# Генерация encryption ключей
bin/rails db:encryption:init
```

Скопируйте сгенерированные ключи в `.env.production`.

### 3.5 Настройка базы данных

```bash
# Загрузка переменных окружения
export $(cat .env.production | xargs)

# Создание и миграция базы данных
RAILS_ENV=production bin/rails db:create
RAILS_ENV=production bin/rails db:migrate

# (Опционально) Загрузка начальных данных
RAILS_ENV=production bin/rails db:seed
```

### 3.6 Компиляция ассетов

```bash
RAILS_ENV=production bin/rails assets:precompile
```

## 4. Настройка веб-сервера (Nginx + Puma)

### 4.1 Установка Nginx

```bash
sudo apt install -y nginx
```

### 4.2 Настройка Nginx

Создайте конфигурацию для приложения:

```bash
sudo nano /etc/nginx/sites-available/vorthex
```

Добавьте следующую конфигурацию:

```nginx
upstream puma {
  server unix:///var/www/vorthex/crypto_messenger/tmp/sockets/puma.sock;
}

server {
  listen 80;
  server_name yourdomain.com www.yourdomain.com;

  root /var/www/vorthex/crypto_messenger/public;
  access_log /var/www/vorthex/crypto_messenger/log/nginx.access.log;
  error_log /var/www/vorthex/crypto_messenger/log/nginx.error.log info;

  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  try_files $uri/index.html $uri @puma;
  
  location @puma {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://puma;
  }

  # WebSocket support для Action Cable
  location /cable {
    proxy_pass http://puma;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}
```

### 4.3 Активация конфигурации

```bash
sudo ln -s /etc/nginx/sites-available/vorthex /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4.4 Настройка Puma

Создайте директорию для сокета:

```bash
mkdir -p /var/www/vorthex/crypto_messenger/tmp/sockets
```

Отредактируйте `config/puma.rb` (если нужно):

```ruby
# Добавьте или измените
bind "unix:///var/www/vorthex/crypto_messenger/tmp/sockets/puma.sock"
```

## 5. Настройка systemd для автозапуска

### 5.1 Создание Puma сервиса

```bash
sudo nano /etc/systemd/system/puma.service
```

Добавьте следующее:

```ini
[Unit]
Description=Puma HTTP Server for Vorthex
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/var/www/vorthex/crypto_messenger
EnvironmentFile=/var/www/vorthex/crypto_messenger/.env.production
ExecStart=/home/your_username/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

### 5.2 Создание Solid Queue сервиса (для фоновых задач)

```bash
sudo nano /etc/systemd/system/solid-queue.service
```

```ini
[Unit]
Description=Solid Queue Worker for Vorthex
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/var/www/vorthex/crypto_messenger
EnvironmentFile=/var/www/vorthex/crypto_messenger/.env.production
ExecStart=/home/your_username/.rbenv/shims/bundle exec bin/jobs
Restart=always

[Install]
WantedBy=multi-user.target
```

### 5.3 Создание Solid Cable сервиса (для WebSocket)

```bash
sudo nano /etc/systemd/system/solid-cable.service
```

```ini
[Unit]
Description=Solid Cable Server for Vorthex
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/var/www/vorthex/crypto_messenger
EnvironmentFile=/var/www/vorthex/crypto_messenger/.env.production
ExecStart=/home/your_username/.rbenv/shims/bundle exec bin/thrust cable
Restart=always

[Install]
WantedBy=multi-user.target
```

### 5.4 Запуск сервисов

```bash
# Перезагрузка systemd
sudo systemctl daemon-reload

# Запуск сервисов
sudo systemctl start puma
sudo systemctl start solid-queue
sudo systemctl start solid-cable

# Включение автозапуска
sudo systemctl enable puma
sudo systemctl enable solid-queue
sudo systemctl enable solid-cable

# Проверка статуса
sudo systemctl status puma
sudo systemctl status solid-queue
sudo systemctl status solid-cable
```

## 6. Настройка SSL с Let's Encrypt (опционально, но рекомендуется)

### 6.1 Установка Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 6.2 Получение SSL сертификата

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Следуйте инструкциям. Certbot автоматически настроит Nginx для HTTPS.

### 6.3 Автообновление сертификата

```bash
# Проверка автообновления
sudo certbot renew --dry-run
```

Certbot автоматически создаст cron задачу для обновления.

## 7. Настройка файрвола

```bash
# Разрешить SSH, HTTP, HTTPS
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```

## 8. Создание первого администратора

```bash
cd /var/www/vorthex
RAILS_ENV=production bin/rails console
```

В консоли Rails:

```ruby
User.create!(
  username: 'admin',
  email: 'admin@example.com',
  password: 'secure_password',
  password_confirmation: 'secure_password',
  admin: true
)
```

## 9. Мониторинг и логи

### 9.1 Просмотр логов

```bash
# Логи Puma
sudo journalctl -u puma -f

# Логи Nginx
sudo tail -f /var/www/vorthex/crypto_messenger/log/nginx.access.log
sudo tail -f /var/www/vorthex/crypto_messenger/log/nginx.error.log

# Логи приложения
tail -f /var/www/vorthex/crypto_messenger/log/production.log
```

### 9.2 Перезапуск сервисов

```bash
# Перезапуск Puma после изменений
sudo systemctl restart puma

# Перезапуск Nginx
sudo systemctl restart nginx

# Перезапуск всех сервисов
sudo systemctl restart puma solid-queue solid-cable nginx
```

## 10. Обновление приложения

```bash
cd /var/www/vorthex/crypto_messenger

# Получение последних изменений
git pull origin main

# Установка зависимостей
bundle install --without development test

# Миграция базы данных
RAILS_ENV=production bin/rails db:migrate

# Компиляция ассетов
RAILS_ENV=production bin/rails assets:precompile

# Перезапуск сервисов
sudo systemctl restart puma solid-queue solid-cable
```

## 11. Бэкап базы данных

### 11.1 Создание бэкапа

```bash
# Ручной бэкап
pg_dump -U vorthex vorthex_production > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 11.2 Автоматический бэкап (cron)

```bash
crontab -e
```

Добавьте:

```cron
# Ежедневный бэкап в 3:00 AM
0 3 * * * cd /var/www/vorthex/crypto_messenger && pg_dump -U vorthex vorthex_production > /var/backups/vorthex_$(date +\%Y\%m\%d).sql
```

Создайте директорию для бэкапов:

```bash
sudo mkdir -p /var/backups
sudo chown $USER:$USER /var/backups
```

## 12. Решение проблем

### Проблема: Puma не запускается

```bash
# Проверка логов
sudo journalctl -u puma -n 50

# Проверка прав доступа
ls -la /var/www/vorthex/crypto_messenger/tmp/sockets/

# Создание директории, если не существует
mkdir -p /var/www/vorthex/crypto_messenger/tmp/sockets
```

### Проблема: Ошибка подключения к базе данных

```bash
# Проверка статуса PostgreSQL
sudo systemctl status postgresql

# Проверка подключения
psql -U vorthex -d vorthex_production -h localhost
```

### Проблема: Asset файлы не загружаются

```bash
# Перекомпиляция ассетов
RAILS_ENV=production bin/rails assets:clobber
RAILS_ENV=production bin/rails assets:precompile

# Проверка прав доступа
sudo chown -R $USER:$USER /var/www/vorthex/crypto_messenger/public
```

## 13. Проверка работоспособности

После развертывания откройте браузер и перейдите по адресу:
- HTTP: http://yourdomain.com
- HTTPS: https://yourdomain.com

Проверьте:
- ✅ Загружается главная страница
- ✅ Работает регистрация
- ✅ Работает вход в систему
- ✅ Создаются комнаты
- ✅ Отправляются сообщения в реальном времени
- ✅ Работают реакции и комментарии

## Полезные команды

```bash
# Проверка статуса всех сервисов
systemctl status puma solid-queue solid-cable nginx postgresql redis

# Просмотр всех процессов Ruby
ps aux | grep ruby

# Проверка использования памяти
free -h

# Проверка дискового пространства
df -h

# Очистка старых логов
find /var/www/vorthex/crypto_messenger/log -name "*.log" -mtime +30 -delete
```

---

## Поддержка

При возникновении проблем:
1. Проверьте логи приложения и сервисов
2. Проверьте файрвол и сетевые настройки
3. Убедитесь, что все сервисы запущены
4. Проверьте права доступа к файлам и директориям

Удачи в развертывании! 🚀
