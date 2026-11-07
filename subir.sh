#!/bin/sh
# Compatibilidad Termux/Linux: en Termux no existe /usr/bin/env.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# Sube el proyecto a GitHub.
# Uso:  ./subir.sh TU_USUARIO [NOMBRE_REPO]
# Antes crea el repositorio vacío en https://github.com/new (sin README).

set -euo pipefail

cd "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v git >/dev/null 2>&1 || {
  printf '[-] Falta git. En Termux: pkg install git\n'
  exit 1
}

USUARIO="${1:-}"
REPO="${2:-MR.Robottico_facil}"

if [ -z "$USUARIO" ]; then
  printf 'Tu usuario de GitHub: '
  IFS= read -r USUARIO
fi
[ -n "$USUARIO" ] || {
  printf '[-] Falta el usuario de GitHub\n'
  exit 1
}

if [ ! -d .git ]; then
  git init -q
fi

if ! git config user.email >/dev/null 2>&1; then
  git config user.name "$USUARIO"
  git config user.email "$USUARIO@users.noreply.github.com"
fi

git add -A
if ! git diff --cached --quiet; then
  git commit -m "MR.ROBOTTICO · HTB Fácil (menú + retos)"
else
  printf '[i] No hay cambios nuevos para commitear\n'
fi

git branch -M main

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "https://github.com/$USUARIO/$REPO.git"
else
  git remote add origin "https://github.com/$USUARIO/$REPO.git"
fi

printf '\n[+] Repositorio: https://github.com/%s/%s\n' "$USUARIO" "$REPO"
printf '[i] Si aún no existe, créalo vacío en https://github.com/new\n'
printf '[i] En el push te pedirá usuario y contraseña: usa un Token (PAT),\n'
printf '    no tu contraseña normal. Créalo en GitHub → Settings → Developer settings.\n\n'

git push -u origin main
