# Установка Vorthex с помощью Kamal

Kamal - это официальный инструмент развертывания для Rails 8, который автоматизирует деплой приложения на любой сервер с Docker.

> **Примечание:** Репозиторий называется `crypto_messenger`, но приложение называется **Vorthex**. Работайте из папки `crypto_messenger` после клонирования.

## Требования

### На локальной машине:
- Ruby 3.3.6
- Kamal gem (`gem install kamal`)
- SSH доступ к серверу
- Git

### На сервере:
- Ubuntu 24.04 LTS (или любой Linux с Docker)
- Docker Engine установлен
- Минимум 2GB RAM
- Открытые порты: 22 (SSH), 80 (HTTP), 443 (HTTPS)

## Подготовка сервера

### 1. Установка Docker на сервере

Подключитесь к серверу через SSH и выполните:

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавление пользователя в группу docker (замените 'username' на ваше имя)
sudo usermod -aG docker username

# Перезайдите в SSH для применения изменений
exit
```

### 2. Проверка Docker

После повторного входа проверьте:

```bash
docker --version
docker ps
```

## Настройка проекта локально

### 1. Клонирование репозитория

```bash
git clone https://github.com/pachugonis/crypto_messenger.git
cd crypto_messenger
```

### 2. Установка Kamal

```bash
gem install kamal
```

### 3. Настройка deploy.yml

Отредактируйте `config/deploy.yml`:

```yaml
service: vorthex
image: vorthex

servers:
  web:
    - YOUR_SERVER_IP  # Замените на IP вашего сервера

# Если используете Docker Hub или другой registry
registry:
  server: ghcr.io  # или hub.docker.com
  username: your-username
  password:
    - KAMAL_REGISTRY_PASSWORD

# Для SSL через Let's Encrypt (опционально)
proxy:
  ssl: true
  host: yourdomain.com

# Переменные окружения
env:
  secret:
    - RAILS_MASTER_KEY
    - POSTGRES_PASSWORD
    - SECRET_KEY_BASE
    - ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
    - ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
    - ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
  clear:
    DATABASE_URL: postgresql://vorthex:password@db:5432/vorthex_production
    REDIS_URL: redis://redis:6379/0
    RAILS_LOG_LEVEL: info

# Accessories для PostgreSQL и Redis
accessories:
  db:
    image: postgres:16-alpine
    host: YOUR_SERVER_IP
    port: "127.0.0.1:5432:5432"
    env:
      clear:
        POSTGRES_USER: vorthex
        POSTGRES_DB: vorthex_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    host: YOUR_SERVER_IP
    port: "127.0.0.1:6379:6379"
    cmd: redis-server --appendonly yes
    directories:
      - data:/data
```

### 4. Создание файла с секретами

Создайте `.kamal/secrets`:

```bash
mkdir -p .kamal
touch .kamal/secrets
chmod 600 .kamal/secrets
```

Добавьте секреты в `.kamal/secrets`:

```bash
# Сгенерируйте секретные ключи
RAILS_MASTER_KEY=$(cat config/master.key)
SECRET_KEY_BASE=$(bin/rails secret)
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=$(openssl rand -hex 32)
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 16)

# Для Docker registry (если используете)
KAMAL_REGISTRY_PASSWORD=your_docker_registry_token
```

Содержимое `.kamal/secrets`:

```env
RAILS_MASTER_KEY=your_master_key_from_config
SECRET_KEY_BASE=your_generated_secret_key_base
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=your_generated_key
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=your_generated_key
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=your_generated_salt
POSTGRES_PASSWORD=your_postgres_password
KAMAL_REGISTRY_PASSWORD=your_registry_token
```

### 5. Проверка SSH подключения

Убедитесь, что можете подключиться к серверу:

```bash
ssh root@YOUR_SERVER_IP
# или
ssh username@YOUR_SERVER_IP
```

Если используете SSH ключ с нестандартным путём, настройте `~/.ssh/config`:

```
Host vorthex
  HostName YOUR_SERVER_IP
  User root
  IdentityFile ~/.ssh/your_key
```

## Развертывание с Kamal

### 1. Первоначальная установка (setup)

Эта команда подготовит сервер и установит Docker, если его нет:

```bash
kamal setup
```

Эта команда:
- Проверит Docker на сервере
- Создаст необходимые директории
- Запустит accessories (PostgreSQL, Redis)
- Соберёт Docker образ
- Развернёт приложение
- Запустит Traefik proxy (если включен SSL)

### 2. Инициализация базы данных

После первого деплоя выполните миграции:

```bash
kamal app exec 'bin/rails db:create'
kamal app exec 'bin/rails db:migrate'
kamal app exec 'bin/rails db:seed'
```

### 3. Создание администратора

```bash
kamal app exec --interactive 'bin/rails console'
```

В консоли:

```ruby
User.create!(
  username: 'admin',
  email: 'admin@example.com',
  password: 'secure_password',
  password_confirmation: 'secure_password',
  admin: true
)
exit
```

## Управление приложением

### Развертывание обновлений

После изменений в коде:

```bash
git pull origin main
kamal deploy
```

Kamal автоматически:
- Соберёт новый образ
- Развернёт новую версию
- Выполнит zero-downtime переключение
- Откатится автоматически при ошибках

### Полезные команды

#### Просмотр логов

```bash
# Логи приложения
kamal app logs -f

# Логи конкретного контейнера
kamal app logs --since 1h

# Логи базы данных
kamal accessory logs db -f

# Логи Redis
kamal accessory logs redis -f
```

#### Консоль Rails

```bash
# Интерактивная консоль
kamal console

# Или полный вариант
kamal app exec --interactive --reuse 'bin/rails console'
```

#### Shell доступ

```bash
# Bash в контейнере приложения
kamal shell

# Или
kamal app exec --interactive --reuse 'bash'
```

#### Перезапуск

```bash
# Перезапуск приложения
kamal app restart

# Перезапуск accessories
kamal accessory restart db
kamal accessory restart redis

# Перезапуск всего
kamal restart
```

#### Остановка

```bash
# Остановить приложение
kamal app stop

# Остановить accessories
kamal accessory stop db
kamal accessory stop redis

# Остановить всё
kamal stop
```

#### Проверка статуса

```bash
# Статус приложения
kamal app details

# Статус accessories
kamal accessory details db
kamal accessory details redis

# Информация о контейнерах
kamal app containers
```

#### Откат версии

```bash
# Откатиться к предыдущей версии
kamal rollback
```

#### Удаление

```bash
# Удалить приложение (оставить данные)
kamal app remove

# Удалить всё включая данные
kamal remove
```

## Работа с базой данных

### Бэкап базы данных

```bash
# Создать бэкап
kamal accessory exec db 'pg_dump -U vorthex vorthex_production' > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление из бэкапа

```bash
cat backup.sql | kamal accessory exec -i db 'psql -U vorthex vorthex_production'
```

### Доступ к PostgreSQL

```bash
kamal accessory exec -i db 'psql -U vorthex vorthex_production'
```

### Миграции

```bash
# Запустить миграции
kamal app exec 'bin/rails db:migrate'

# Откатить последнюю миграцию
kamal app exec 'bin/rails db:rollback'

# Проверить статус миграций
kamal app exec 'bin/rails db:migrate:status'
```

## Настройка SSL/HTTPS

### Автоматический SSL через Traefik

Раскомментируйте в `config/deploy.yml`:

```yaml
proxy:
  ssl: true
  host: yourdomain.com
```

Затем выполните:

```bash
kamal traefik reboot
kamal deploy
```

Traefik автоматически получит сертификат Let's Encrypt.

### Ручная настройка Nginx

Если предпочитаете Nginx:

1. Отключите Traefik в deploy.yml (закомментируйте proxy)
2. Установите Nginx на сервере
3. Настройте reverse proxy (см. DEPLOYMENT.md)

## Мониторинг

### Использование ресурсов

```bash
# На сервере
ssh YOUR_SERVER_IP
docker stats
```

### Проверка здоровья

```bash
# Проверка приложения
curl http://YOUR_SERVER_IP/up

# Проверка PostgreSQL
kamal accessory exec db 'pg_isready -U vorthex'

# Проверка Redis
kamal accessory exec redis 'redis-cli ping'
```

## Масштабирование

### Добавление серверов

В `config/deploy.yml`:

```yaml
servers:
  web:
    - 192.168.0.1
    - 192.168.0.2
    - 192.168.0.3
```

Затем:

```bash
kamal setup
```

### Выделенные job серверы

```yaml
servers:
  web:
    - 192.168.0.1
  job:
    hosts:
      - 192.168.0.2
    cmd: bin/jobs
```

## Решение проблем

### Сборка образа не удаётся

```bash
# Очистить кеш Docker
kamal build push --no-cache

# Проверить логи сборки
kamal build details
```

### Контейнер не запускается

```bash
# Проверить логи
kamal app logs

# Проверить переменные окружения
kamal app exec 'env'

# Проверить конфигурацию
kamal config
```

### Проблемы с базой данных

```bash
# Проверить статус PostgreSQL
kamal accessory logs db

# Перезапустить базу данных
kamal accessory restart db

# Проверить подключение
kamal app exec 'bin/rails runner "puts ActiveRecord::Base.connection.active?"'
```

### SSH проблемы

```bash
# Проверить SSH подключение
ssh -v YOUR_SERVER_IP

# Использовать конкретный ключ
kamal setup --hosts YOUR_SERVER_IP --ssh-identity ~/.ssh/your_key
```

### Порты заняты

```bash
# На сервере проверить занятые порты
ssh YOUR_SERVER_IP
sudo lsof -i :80
sudo lsof -i :443
```

## Оптимизация

### Ускорение сборки

В `config/deploy.yml`:

```yaml
builder:
  arch: amd64
  cache:
    type: registry
    options: mode=max
```

### Использование удалённого builder

```yaml
builder:
  remote: ssh://docker@builder-server
```

### Настройка логирования

```yaml
env:
  clear:
    RAILS_LOG_LEVEL: warn  # Уменьшить объём логов
```

## Continuous Deployment с GitHub Actions

Создайте `.github/workflows/deploy.yml`:

```yaml
name: Deploy with Kamal

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.6
          bundler-cache: true
      
      - name: Install Kamal
        run: gem install kamal
      
      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan -H ${{ secrets.SERVER_IP }} >> ~/.ssh/known_hosts
      
      - name: Set up secrets
        run: |
          mkdir -p .kamal
          echo "${{ secrets.KAMAL_SECRETS }}" > .kamal/secrets
      
      - name: Deploy
        run: kamal deploy
```

Добавьте secrets в GitHub:
- `SSH_PRIVATE_KEY` - ваш приватный SSH ключ
- `SERVER_IP` - IP вашего сервера
- `KAMAL_SECRETS` - содержимое .kamal/secrets

## Полезные алиасы

Добавьте в `~/.bashrc` или `~/.zshrc`:

```bash
alias kdeploy='kamal deploy'
alias klogs='kamal app logs -f'
alias kconsole='kamal console'
alias kshell='kamal shell'
alias krestart='kamal app restart'
alias krollback='kamal rollback'
```

## Сравнение с Docker Compose

| Функция | Kamal | Docker Compose |
|---------|-------|----------------|
| Zero-downtime deploys | ✅ | ❌ |
| Автоматический rollback | ✅ | ❌ |
| Удалённое развертывание | ✅ | ❌ |
| Множество серверов | ✅ | ❌ |
| Встроенный SSL | ✅ | ❌ |
| Простота локальной разработки | ❌ | ✅ |

**Рекомендация:**
- Используйте **Docker Compose** для локальной разработки и тестирования
- Используйте **Kamal** для production развертывания

## Поддержка

При возникновении проблем:

1. Проверьте логи: `kamal app logs`
2. Проверьте конфигурацию: `kamal config`
3. Проверьте статус: `kamal app details`
4. Официальная документация: https://kamal-deploy.org

---

Удачи в развертывании! 🚀
