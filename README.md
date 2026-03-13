# 🚗 Auto Service App

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Yandex MapKit](https://img.shields.io/badge/Yandex_MapKit-FFCC00?style=for-the-badge&logo=yandex&logoColor=black)](https://yandex.ru/dev/mapkit/)

*Read this in other languages: [English](#english) | [Русский](#russian)*

---

<a id="english"></a>
## 🇬🇧 English

A comprehensive mobile application designed for modern drivers, offering an integrated experience for finding auto services, purchasing spare parts, and seamless navigation. Built with **Flutter** based on **Clean Architecture** principles.

### ✨ Key Features

- **🗺️ Interactive Map & Navigation**: Real-time map powered by Yandex MapKit to locate nearby auto services, gas stations, and navigate directly to them.
- **🛒 E-commerce for Spare Parts**: Integrated store with a shopping cart to browse and purchase auto parts.
- **📅 Service Booking System**: Conveniently schedule unkeep and repair services.
- **👤 User Profiles & History**: Personal accounts to manage active bookings and view service history.
- **🌐 Localization**: Full support for both English (by default), Russian, and Uzbek languages.

### 🛠️ Tech Stack & Architecture

- **Framework**: Flutter (Cross-platform iOS & Android)
- **Architecture**: Clean Architecture (Core, Data, Presentation layers)
- **State Management**: Provider
- **Maps Location & Routing**: Yandex MapKit
- **Local Storage**: SharedPreferences & Secure Storage
- **Localization**: Easy Localization
- **API Networking**: HTTP with custom interceptors

### 🏗️ Project Structure

```text
lib/
├── core/              # Core functionality (config, typography, constants, models)
├── data/              # Data layer (DataSources, APIs)
└── presentation/      # UI layer (Screens, Widgets, State Providers)
```

### 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AAAbdullo/auto_service.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```
*(Note: Ensure you have your Yandex MapKit API keys configured if running from scratch).*

---

<a id="russian"></a>
## 🇷🇺 Русский

Комплексное мобильное приложение для современных водителей, объединяющее поиск автосервисов, покупку запчастей и удобную навигацию. Построено на **Flutter** с использованием принципов **Clean Architecture**.

### ✨ Основные возможности

- **🗺️ Интерактивная карта и Навигация**: Карта в реальном времени на базе Yandex MapKit для поиска ближайших СТО, заправок и построения маршрутов.
- **🛒 Магазин запчастей**: Встроенный каталог с корзиной для удобной покупки автозапчастей.
- **📅 Система бронирования**: Удобная запись на техническое обслуживание и ремонт.
- **👤 Личный кабинет**: Управление профилем пользователя, просмотр активных бронирований и истории.
- **🌐 Локализация**: Полная поддержка русского и узбекского языков.

### 🛠️ Технологии и Архитектура

- **Фреймворк**: Flutter (iOS & Android)
- **Архитектура**: Clean Architecture (слои: Core, Data, Presentation)
- **Управление состоянием (State Management)**: Provider
- **Карты и Навигация**: Yandex MapKit
- **Локальное хранилище**: SharedPreferences & Secure Storage
- **Локализация**: Easy Localization
- **Сеть**: пакет `http` собственной оберткой-интерцептором.

### 🏗️ Структура проекта

```text
lib/
├── core/              # Базовый функционал (конфиги, константы, утилиты)
├── data/              # Слой данных (API, источники данных)
└── presentation/      # UI-слой (Экраны, Виджеты, Провайдеры состояний)
```

### 🚀 Быстрый старт

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/AAAbdullo/auto_service.git
   ```
2. **Установите зависимости:**
   ```bash
   flutter pub get
   ```
3. **Запустите приложение:**
   ```bash
   flutter run
   ```
*(Примечание: Убедитесь, что настроены API ключи Yandex MapKit).*

---
*Developed by [AAAbdullo](https://github.com/AAAbdullo)*
