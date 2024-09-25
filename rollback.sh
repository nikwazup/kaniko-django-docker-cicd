#!/bin/bash

# Собираем список приложений из директорий, содержащих models.py или apps.py
mapfile -t apps < <(find . -name "models.py" -o -name "apps.py" | sed -r 's|/[^/]+$||' | sed 's|^\./||' | sort | uniq)

rollback_last_migration() {
  app_name=$1

  # Получаем последнюю применённую миграцию
  last_migration=$(python manage.py showmigrations "$app_name" | grep "\[X\]" | tail -1 | awk '{print $2}')

  # Проверяем, нашлась ли миграция
  if [[ -z "$last_migration" ]]; then
    echo "Миграций для $app_name не найдено или они не применены."
  else
    echo "Последняя применённая миграция для $app_name: $last_migration"

    # Откат на предыдущую миграцию
    previous_migration=$(python manage.py showmigrations "$app_name" | grep "\[X\]" | tail -2 | head -1 | awk '{print $2}')
    
    if [[ -z "$previous_migration" ]]; then
      echo "Нет предыдущей миграции для отката в $app_name."
    else
      echo "Откатываем на миграцию: $previous_migration"
      python manage.py migrate "$app_name" "$previous_migration"
    fi
  fi
}

# Применение функции для каждого приложения
for app in "${apps[@]}"; do
  rollback_last_migration "$app"
done
