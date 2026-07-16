# debootstrap для Astra Linux

Debian-пакет `debootstrap` версии `1.0.141+astra1-1` с поддержкой Astra Linux.
Пакет основан на upstream commit `8457f34b4c30a09e7acfabf5ab153146cc3470ed`.
Исходники не хранятся в этом репозитории: сборщик скачивает зафиксированный
архив и проверяет его SHA-256 перед применением Debian packaging.

В сборке:

- применяются `0001-arch-detect.patch` и `0002-def_components.patch`;
- добавляются suite-скрипты `1.8_x86-64` и `orel`;
- устанавливаются Astra suite aliases из исходного `package.yml`;
- `HOST_ARCH` принудительно устанавливается в `amd64`.

Это Debian-аналог исходного Solus-рецепта `package.yml`: пакет называется
`debootstrap` и при установке заменяет установленную системную версию.

## Установка из APT-репозитория

После первой публикации тега и включения GitHub Pages с источником
**GitHub Actions**:

```sh
echo "deb [trusted=yes] https://kibadima1.github.io/debootstrap-astra stable main" \
  | sudo tee /etc/apt/sources.list.d/debootstrap-astra.list
sudo apt update
sudo apt install debootstrap
```

Репозиторий пока не подписан, поэтому в примере явно используется
`trusted=yes`. Для production рекомендуется добавить подпись `Release` и
распространять публичный ключ отдельно.

## Установка файла из GitHub Releases

Скачайте `.deb` нужного релиза и установите его:

```sh
sudo apt install ./debootstrap_1.0.141+astra1-1_all.deb
```

## Использование

Пример для Astra Linux Special Edition 1.8:

```sh
sudo debootstrap \
  --arch=amd64 \
  1.8_x86-64 \
  ./astra-root \
  https://download.astralinux.ru/astra/stable/1.8_x86-64/main-repository/
```

Для собственного набора компонентов передайте стандартный параметр
`--components`, например `--components=main,contrib,non-free`.

## Локальная сборка

На Debian/Ubuntu скрипт скачивает pinned upstream во временный каталог и
использует установленный `dpkg-buildpackage`. На macOS и других системах он
автоматически использует Docker:

```sh
./scripts/build.sh
```

Готовый пакет будет помещён в `dist/`. Проверка метаданных и файлов:

```sh
dpkg-deb --info dist/debootstrap_*_all.deb
dpkg-deb --contents dist/debootstrap_*_all.deb
```

## Выпуск версии

1. Обновите `debian/changelog`.
2. Создайте и отправьте тег, например `v1.0.141-astra1-1`.
3. Workflow `release.yml` соберёт пакет, добавит `.deb` в GitHub Release и
   пересоберёт APT-репозиторий в GitHub Pages.

Обычные push и pull request только проверяют сборку и сохраняют `.deb` как CI
artifact. Автоматического push из workflow нет.
