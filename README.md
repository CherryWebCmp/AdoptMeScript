# ADOPT ME ULTIMATE

Локальный GUI для Roblox Adopt Me: виртуальный инвентарь питомцев, редактор карточек, симулятор трейда, каталог, настройки.
**Всё — локальная визуальная симуляция внутри GUI.** Проект не меняет серверный инвентарь, не вызывает Remote-события игры и не действует от имени других игроков.

## Структура репозитория

```
Loader.lua          ← одна строка для Executor (хранить в репозитории для копирования)
Main.lua            ← точка входа, подгружает модули по HTTP
Settings.lua        ← настройки + файловое хранилище (writefile/readfile, если есть)
PetCatalog.lua      ← каталог питомцев и редкости
Inventory.lua       ← виртуальный инвентарь (добавить/изменить/удалить/фильтры/сортировка)
TradeSimulator.lua  ← логика симуляции обмена (локальная)
UI.lua              ← окно, темы, компоненты, модальные окна, плавающая кнопка
PetForm.lua         ← общая форма характеристик питомца
PageInventory.lua   PageAdd.lua   PageTrade.lua
PageCatalog.lua     PageSettings.lua   PageInfo.lua
README.md
```

Все `.lua` лежат в **корне** репозитория (Main.lua берёт модули по адресу `BASE .. "Имя.lua"`).

## Публикация на GitHub (через сайт)

1. Зарегистрируйтесь/войдите на github.com → **New repository**. Имя, например, `AdoptMeUltimate`. Видимость — **Public**.
2. На странице репозитория: **Add file → Upload files**, перетащите все файлы из этой папки → **Commit changes**.
3. Откройте `Main.lua` в репозитории → значок карандаша → найдите строку
   `local DEFAULT_BASE = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/"`
   и замените `YOUR_USER` на ваш ник GitHub, `YOUR_REPO` на имя репозитория → **Commit changes**.
   (Если основная ветка называется не `main`, поменяйте и её.)
4. Проверьте Raw-ссылку в браузере: `https://raw.githubusercontent.com/ВАШ_НИК/ВАШ_РЕПО/main/Main.lua` — должен открыться исходный код.
5. Строка для Executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ВАШ_НИК/ВАШ_РЕПО/main/Main.lua"))()
```

### Через git (альтернатива)
```
git init && git add . && git commit -m "ADOPT ME ULTIMATE v1.0.0"
git branch -M main
git remote add origin https://github.com/ВАШ_НИК/ВАШ_РЕПО.git
git push -u origin main
```

### Вариант без правки Main.lua
Адрес можно передать в самой строке (она чуть длиннее):
```lua
getgenv().AU_BASE="https://raw.githubusercontent.com/ВАШ_НИК/ВАШ_РЕПО/main/";loadstring(game:HttpGet(AU_BASE.."Main.lua"))()
```

## Обновление
1. Измените нужный файл на GitHub (карандаш → Commit changes) или сделайте `git push`.
2. Пользователям ничего менять не нужно: загрузчик при каждом запуске скачивает актуальные файлы (добавляется `?v=время`, чтобы обойти кэш Raw).
3. Повторный запуск строки автоматически выгружает старое окно и загружает новое.
4. Для смены версии поправьте `VERSION` в `Main.lua`.

## Локальная проверка без GitHub
Положите все `.lua` в `workspace/AdoptMeUltimate/` вашего инжектора и выполните:
```lua
getgenv().AU_LOCAL = true
loadstring(readfile("AdoptMeUltimate/Main.lua"))()
```

## Кастомизация
- Новые питомцы: добавьте имена в таблицу `RAW` в `PetCatalog.lua` (по редкостям). Каталог составлен вручную и может быть неполным; редкость любой записи можно менять в редакторе.
- Картинки: в каталоге нет ID изображений (они не выдумывались). Для карточки можно указать числовой ID вручную в форме; без него показываются инициалы на цветной плитке.

## Управление
Перетаскивание — за заголовок; размер — угол ◢; «—» сворачивает; «✕» скрывает (вернуть — плавающая кнопка 🐾 или RightShift).
