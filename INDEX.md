# 📚 Навигатор по документации Auto Service App

## 🎯 С чего начать?

### Вы здесь впервые? 
👉 **[START_HERE.md](START_HERE.md)** - Начните отсюда! (5 минут)

### Хотите визуальную инструкцию?
👉 **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** - Пошаговая визуальная схема

### Нужна быстрая шпаргалка?
👉 **[CHEATSHEET.md](CHEATSHEET.md)** - Все команды в одном месте

---

## 📖 Полная документация

### 🚀 Установка и запуск
| Файл | Описание | Когда использовать |
|------|----------|-------------------|
| **[START_HERE.md](START_HERE.md)** | Быстрый старт | Первый запуск проекта |
| **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** | Детальная установка | Нужна подробная информация |
| **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** | Визуальная схема | Предпочитаете схемы |

### 🐛 Решение проблем
| Файл | Описание | Когда использовать |
|------|----------|-------------------|
| **[DEBUG_GUIDE.md](DEBUG_GUIDE.md)** | Полное руководство по отладке | Что-то не работает |
| **[CHECKLIST.md](CHECKLIST.md)** | Чек-лист проверки | Проверить настройки |

### 📝 Справочники
| Файл | Описание | Когда использовать |
|------|----------|-------------------|
| **[CHEATSHEET.md](CHEATSHEET.md)** | Шпаргалка команд | Нужна быстрая справка |
| **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** | Список изменений | Узнать что было исправлено |
| **[README.md](README.md)** | Общая информация | Обзор проекта |

---

## 🛠️ Скрипты и автоматизация

### Исполняемые скрипты
| Скрипт | Команда | Описание |
|--------|---------|----------|
| **menu.sh** | `./menu.sh` | 🌟 Интерактивное меню (РЕКОМЕНДУЕТСЯ) |
| **run.sh** | `./run.sh` | Быстрый запуск приложения |
| **setup_ios.sh** | `./setup_ios.sh` | Первая настройка проекта |
| **make_executable.sh** | `./make_executable.sh` | Сделать скрипты исполняемыми |

---

## 📊 Структура документации

```
📚 Документация
│
├── 🎯 Быстрый старт
│   ├── START_HERE.md          ⭐ Начните отсюда!
│   ├── VISUAL_GUIDE.md        📊 Визуальная схема
│   └── CHEATSHEET.md          💡 Быстрая справка
│
├── 📖 Детальные инструкции
│   ├── SETUP_INSTRUCTIONS.md  🔧 Установка
│   ├── DEBUG_GUIDE.md         🐛 Отладка
│   └── CHECKLIST.md           ✅ Проверки
│
├── 📋 Справочная информация
│   ├── CHANGES_SUMMARY.md     📝 Изменения
│   ├── README.md              📄 О проекте
│   └── INDEX.md               📚 Этот файл
│
└── 🛠️ Автоматизация
    ├── menu.sh                🎛️ Меню
    ├── run.sh                 🚀 Запуск
    ├── setup_ios.sh           ⚙️ Настройка
    └── make_executable.sh     🔑 Права
```

---

## 🎓 Рекомендуемый порядок изучения

### Для новичков в проекте:
1. **[START_HERE.md](START_HERE.md)** - Общее понимание (5 мин)
2. **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** - Визуальная схема (3 мин)
3. **Запустите**: `./menu.sh` → "🚀 Запустить приложение"
4. **[CHEATSHEET.md](CHEATSHEET.md)** - Сохраните для справки

### Для решения проблем:
1. **[CHECKLIST.md](CHECKLIST.md)** - Проверьте настройки
2. **[DEBUG_GUIDE.md](DEBUG_GUIDE.md)** - Найдите решение
3. **`flutter doctor -v`** - Диагностика
4. **`./setup_ios.sh`** - Переустановка (если ничего не помогло)

### Для опытных разработчиков:
1. **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - Что изменилось
2. **[README.md](README.md)** - Архитектура проекта
3. **[CHEATSHEET.md](CHEATSHEET.md)** - Команды
4. Начинайте работу!

---

## 💡 Полезные советы по документации

### 🔍 Быстрый поиск информации:
- **Команды?** → CHEATSHEET.md
- **Не работает?** → DEBUG_GUIDE.md
- **Первый раз?** → START_HERE.md
- **Схемы?** → VISUAL_GUIDE.md
- **Проверка?** → CHECKLIST.md

### 📱 Быстрые ссылки из Terminal:
```bash
# Открыть документ
open START_HERE.md
open CHEATSHEET.md
open DEBUG_GUIDE.md

# Или просмотреть в терминале
cat CHEATSHEET.md
less DEBUG_GUIDE.md
```

### 🔖 Создать закладки:
Добавьте эти команды в `.zshrc` или `.bashrc`:
```bash
alias asdoc='open /Users/marcus/Documents/auto_service_app/START_HERE.md'
alias asrun='cd /Users/marcus/Documents/auto_service_app && ./menu.sh'
alias ascheat='open /Users/marcus/Documents/auto_service_app/CHEATSHEET.md'
```

---

## 🎯 Частые вопросы

| Вопрос | Ответ |
|--------|-------|
| С чего начать? | [START_HERE.md](START_HERE.md) |
| Не запускается | [DEBUG_GUIDE.md](DEBUG_GUIDE.md) |
| Какие команды? | [CHEATSHEET.md](CHEATSHEET.md) |
| Как настроить? | [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) |
| Что изменилось? | [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) |
| Визуальная схема? | [VISUAL_GUIDE.md](VISUAL_GUIDE.md) |

---

## 🚀 Самый быстрый способ начать

```bash
cd /Users/marcus/Documents/auto_service_app
chmod +x menu.sh
./menu.sh
```

Выберите: **"🚀 Запустить приложение"**

---

## 📞 Дополнительная помощь

Если не нашли ответ в документации:
1. Проверьте **[CHECKLIST.md](CHECKLIST.md)**
2. Изучите **[DEBUG_GUIDE.md](DEBUG_GUIDE.md)**
3. Запустите `flutter doctor -v`
4. Переустановите через `./setup_ios.sh`

---

## ✨ Полезные команды для работы с документацией

```bash
# Просмотр списка файлов
ls -la *.md

# Поиск по всей документации
grep -r "ключевое слово" *.md

# Подсчет строк в документации
wc -l *.md

# Просмотр с подсветкой синтаксиса (если установлен bat)
bat START_HERE.md
```

---

**Совет:** Добавьте эту страницу в закладки! Она поможет быстро найти нужную информацию. 📚

**Следующий шаг:** Откройте **[START_HERE.md](START_HERE.md)** и начните работу! 🚀
