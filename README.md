# Divinum Officium - Polska Wersja

Fork projektu Divinum Officium dostosowany do potrzeb polskich użytkowników, z domyślnymi ustawieniami języka polskiego i tekstami przedreformowymi (pre-1955).


## Funkcje specjalne

- **Polska lokalizacja** - domyślnie drugi język aktywny i ustawiony na polski (obok łaciny)
- **Teksty tradycyjne** - wersje przedreformowe (pre-1955) jako domyślne
- **Prosta instalacja** - zautomatyzowany proces - przez Dockera
- **Elastyczna konfiguracja** - możliwość wyboru portu


## Instalacja

### Wymagania wstępne
- System Linux
- Zainstalowany Docker
- Uprawnienia sudo

### Kroki instalacyjne (Docker Container)

1. Sklonuj repozytorium:
   ```bash
   git clone https://github.com/ethoscatholicus/divinum-officium-pl.git
   cd divinum-officium-pl
   ```

2. Przygotuj skrypt instalacyjny:
   ```bash
   chmod +x deploy.sh
   ```

3. Uruchom proces instalacji:
   ```bash
   ./deploy.sh
   ```

   Skrypt przeprowadzi Cię przez proces konfiguracji:
   - Poprosi o podanie numeru portu (domyślnie 80)
   - Zapisze konfigurację w pliku `deploy.cfg`

## Konfiguracja

Po instalacji aplikacja będzie dostępna pod adresem:
- `http://localhost:[wybrany_port]` (lokalnie)
- skonfiguruj następnie serwer www, aby mógł korzystać z tak skonfigurowanego endpointu


## Współtworzenie

Zapraszamy do współpracy poprzez:
- Zgłaszanie uwag w zakładce Issues
- Przysyłanie propozycji zmian jako Pull Requests

## Licencja

Projekt dostępny na licencji MIT, zgodnie z licencją oryginalnego projektu.

## Pomoc techniczna

W przypadku problemów:
1. Sprawdź czy Docker działa poprawnie
2. Upewnij się że masz uprawnienia do wybranego portu
3. W razie potrzeby zmodyfikuj ustawienia w pliku `deploy.cfg` i uruchom skrypt ponownie

Skrypt `deploy.sh` automatycznie wykrywa architekturę systemu i dostosowuje proces instalacji do Twojego środowiska.
Ponowne jego uruchomienie odświeża kontener dockera, np. gdy wprowadzamy zmiany w samym projekcie.
Aby ponownie wybrać domenę i port, usuń `deploy.cfg` i odpal ponownie `deploy.sh`

Implementację można zobaczyć na żywo tutaj:

[brewiarz.etosweb.pl](https://brewiarz.etosweb.pl)


Poniżej oryginalny zapis Readme projektu

---
# divinum-officium

Data files and source code for the
[Divinum Officium](http://www.divinumofficium.com/) project.

This document is intended for people wishing to contribute to the project. To
pray the office, please [visit the website](http://www.divinumofficium.com/).

To generate standalone files (e.g. for electronic eBook readers) see
[How to generate Divine Office files](standalone/tools/epubgen2/README.md).

## Contributing to the project

Contributions are very welcome. To propose a change, please create a GitHub
account if necessary, and then open a **pull request**.

For small changes -- for example, for typographical corrections -- the simplest
way to do so is to navigate to the relevant file in GitHub's repository browser
and use its built-in editor. Any changes made in this way will automatically be
converted to a pull request.

For more substantial changes, please **fork** this repository using the link on
the repository's page on GitHub. This will create a copy of the repository
under your own account to which you may commit freely. When you are ready to
submit your change, GitHub's web interface can be used to create a
corresponding pull request. There are various ways to do this, and the
process is [described in the GitHub
documentation](https://help.github.com/articles/using-pull-requests/).

### Data files

The data files for the office and Mass are contained in the `web/www/horas/`
and `web/www/missa/` directories. Within these directories there is a directory
for each language. The files are UTF-8-encoded text files (Windows-1252
encoding is also supported, but is deprecated). The files are arranged into
sections, with each section beginning with its name enclosed in square
brackets. Please browse the files in the aforementioned directories for
examples.

## Docker

### Production

To pull a pre-built container, pull see docker image `ghcr.io/divinumofficium/divinum-officium:master`.

To get the yml file:
`$ wget https://raw.githubusercontent.com/DivinumOfficium/divinum-officium/master/docker-compose-prod.yml`

You can also use Docker Compose to load a copy of the container in one command:

```bash
docker-compose -f docker-compose-prod.yml up -d
```

This will download Divinum Officium, and run a local copy on your system, bound to
`localhost`, port 80.

When you are done, stop the container by running:

```bash
docker-compose -f docker-compose-prod.yml down
```

### Development

[Docker](https://docker.com/) contains complete development environment
necessary for running Divinum Officium website. To run this project you need to
have docker and [Docker Compose](https://docs.docker.com/compose/) installed on
your system. Run the following command in root directory of project:

```bash
docker-compose up
```

This starts the web server and you can visit the website on
`http://localhost:8080`. It will mount the current web directory into the container
so that you can change files and do live-changes without restarting the container.

#### MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

This permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
