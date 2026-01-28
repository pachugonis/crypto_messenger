# Docker Deployment Guide for Vorthex

Этот гайд описывает развертывание Vorthex с использованием Docker и Docker Compose.

## Требования

- Docker Engine 20.10 или новее
- Docker Compose v2.0 или новее
- Минимум 2GB RAM
- Доменное имя (опционально, для SSL)

## Быстрый старт

### 1. Клонирование репозитория

```bash
git clone https://github.com/pachugonis/crypto_messenger.git vorthex
cd vorthex
```

### 2. Настройка переменных окружения

Скопируйте пример и отредактируйте:

```bash
cp .env.example .env
nano .env
```

**Важно:** Сгенерируйте секретные ключи:

```bash
# Локально (если у вас установлен Rails)
bin/rails secret  # Запустите 4 раза для каждого ключа

# Или используйте OpenSSL
openssl rand -hex 64  # Запустите 4 раза
```

Вставьте сгенерированные ключи в `.env` файл.

### 3. Запуск приложения

```bash
# Сборка и запуск всех сервисов
docker-compose up -d

# Проверка статуса
docker-compose ps
```

### 4. Инициализация базы данных

```bash
# Создание и миграция базы данных
docker-compose exec app bin/rails db:create db:migrate

# (Опционально) Загрузка начальных данных
docker-compose exec app bin/rails db:seed
```

### 5. Создание первого администратора

```bash
docker-compose exec app bin/rails console
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
exit
```

### 6. Доступ к приложению

Откройте браузер: http://localhost

## Архитектура

Docker Compose создает следующие сервисы:

- **app** - Основное Rails приложение (порт 80)
- **worker** - Solid Queue для фоновых задач
- **cable** - Solid Cable для WebSocket/Action Cable
- **db** - PostgreSQL 16 (порт 5432)
- **redis** - Redis 7 (порт 6379)

## Управление контейнерами

### Просмотр логов

```bash
# Все сервисы
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f app
docker-compose logs -f worker
docker-compose logs -f db
```

### Перезапуск сервисов

```bash
# Все сервисы
docker-compose restart

# Конкретный сервис
docker-compose restart app
```

### Остановка

```bash
# Остановка без удаления контейнеров
docker-compose stop

# Остановка и удаление контейнеров
docker-compose down

# Остановка с удалением volumes (УДАЛЯЕТ ДАННЫЕ!)
docker-compose down -v
```

### Обновление приложения

```bash
# Получить последние изменения
git pull origin main

# Пересобрать и перезапустить
docker-compose build
docker-compose up -d

# Запустить миграции
docker-compose exec app bin/rails db:migrate

# Перезапустить сервисы
docker-compose restart app worker cable
```

## Работа с базой данных

### Бэкап базы данных

```bash
docker-compose exec db pg_dump -U vorthex vorthex_production > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление из бэкапа

```bash
docker-compose exec -T db psql -U vorthex vorthex_production < backup.sql
```

### Доступ к PostgreSQL CLI

```bash
docker-compose exec db psql -U vorthex vorthex_production
```

### Доступ к Redis CLI

```bash
docker-compose exec redis redis-cli
```

## Настройка SSL/HTTPS с Nginx

Для production рекомендуется использовать Nginx как reverse proxy перед Docker контейнерами.

### Nginx конфигурация

Создайте файл `/etc/nginx/sites-available/vorthex`:

```nginx
upstream vorthex {
  server localhost:80;
}

server {
  listen 80;
  server_name yourdomain.com;

  location / {
    proxy_pass http://vorthex;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  # WebSocket support
  location /cable {
    proxy_pass http://vorthex;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
  }
}
```

Активируйте конфигурацию:

```bash
sudo ln -s /etc/nginx/sites-available/vorthex /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Установка SSL с Certbot

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## Мониторинг

### Использование ресурсов

```bash
docker stats
```

### Проверка здоровья контейнеров

```bash
docker-compose ps
```

### Проверка состояния базы данных

```bash
docker-compose exec db pg_isready -U vorthex
```

### Проверка Redis

```bash
docker-compose exec redis redis-cli ping
```

## Отладка

### Запуск Rails консоли

```bash
docker-compose exec app bin/rails console
```

### Запуск bash в контейнере

```bash
docker-compose exec app bash
```

### Проверка переменных окружения

```bash
docker-compose exec app env
```

### Очистка кеша

```bash
docker-compose exec app bin/rails cache:clear
```

## Production конфигурация

### Изменение портов

Отредактируйте `docker-compose.yml`:

```yaml
services:
  app:
    ports:
      - "8080:80"  # Изменить 80 на любой другой порт
```

### Использование внешней БД

Закомментируйте сервис `db` в `docker-compose.yml` и обновите `DATABASE_URL` в `.env`:

```env
DATABASE_URL=postgresql://user:password@external-host:5432/vorthex_production
```

### Volumes для постоянного хранения

Volumes автоматически создаются для:
- `postgres_data` - данные PostgreSQL
- `redis_data` - данные Redis
- `storage_data` - загруженные файлы (Active Storage)

Бэкап volumes:

```bash
docker run --rm -v vorthex_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
```

## Решение проблем

### Контейнеры не запускаются

```bash
# Проверить логи
docker-compose logs

# Проверить конфликты портов
sudo lsof -i :80
sudo lsof -i :5432
```

### Ошибки базы данных

```bash
# Пересоздать базу данных (УДАЛЯЕТ ДАННЫЕ!)
docker-compose down -v
docker-compose up -d
docker-compose exec app bin/rails db:create db:migrate
```

### Проблемы с permissions

```bash
# Исправить права доступа к storage
docker-compose exec app chown -R rails:rails /rails/storage
```

## Очистка

### Удалить все контейнеры и данные

```bash
docker-compose down -v
docker system prune -a
```

### Удалить только images

```bash
docker-compose down
docker rmi vorthex_app vorthex_worker vorthex_cable
```

## Поддержка

При возникновении проблем:
1. Проверьте логи: `docker-compose logs -f`
2. Проверьте статус: `docker-compose ps`
3. Проверьте переменные окружения в `.env`
4. Убедитесь, что все секретные ключи сгенерированы

## Полезные команды

```bash
# Проверка версий
docker --version
docker-compose --version

# Очистка неиспользуемых ресурсов
docker system prune

# Проверка использования диска
docker system df

# Экспорт контейнера
docker export vorthex_app > vorthex_app.tar

# Просмотр процессов в контейнере
docker-compose top
```

---

Удачи в развертывании! 🚀
