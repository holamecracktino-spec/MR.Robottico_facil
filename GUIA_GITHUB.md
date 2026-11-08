# 🚀 Guía: de cero a GitHub con token

Guía rápida para publicar este proyecto (o cualquier otro) en GitHub desde Termux.

---

## Paso 0 — Requisitos

```bash
pkg install git curl
git --version
```

---

## Paso 1 — Preparar el proyecto en local

```bash
mkdir -p ~/mr_robottico_facil
cd ~/mr_robottico_facil
```

Crea tus archivos (`MR.Robottico_facil.sh`, `README.md`, `LICENSE`, `.gitignore`).

Inicializa git y haz el primer commit:

```bash
git init -b main
git add -A
git commit -m "MR.ROBOTTICO · HTB Fácil (menú + retos)"
```

> Si git se queja de identidad:
>
> ```bash
> git config --global user.name "holamecracktino-spec"
> git config --global user.email "holamecracktino-spec@users.noreply.github.com"
> ```

---

## Paso 2 — Crear el repositorio en GitHub

1. Entra a **https://github.com/new**
2. **Repository name:** `MR.Robottico_facil`
3. **Description:** (opcional)

   ```text
   Menú bash para Termux con 19 máquinas Very Easy de Hack The Box: recon, pistas y retos con flags.
   ```

4. Marca **Public**
5. ⚠️ **NO** marques "Add a README file", ni .gitignore, ni license (ya los tienes en local)
6. Pulsa **Create repository**

> Si por error marcas el README, no pasa nada: se arregla con `--force-with-lease` (Paso 5b).

---

## Paso 3 — Crear el token (PAT)

El token es la **contraseña** para hacer push por HTTPS.

1. Abre **https://github.com/settings/tokens/new**
2. **Note:** un nombre único, por ejemplo `Termux-2`
   - Si dice *"Note has already been taken"*, cambia el nombre (`Termux-3`, `MR-Robottico`…)
3. **Expiration:** `30 days` o `90 days`
4. Marca el scope:
   - ✅ **`repo`** (Full control of private repositories)
5. Baja y pulsa **Generate token**
6. Copia el token **en ese momento**:

   ```text
   ghp_xxxxxxxxxxxxxxxxxxxx
   ```

   ⚠️ Solo se muestra una vez. Si lo pierdes, genera otro.

---

## Paso 4 — Conectar el repo local con GitHub

```bash
cd ~/mr_robottico_facil
git remote add origin https://github.com/holamecracktino-spec/MR.Robottico_facil.git
git remote -v
```

Debe mostrar `fetch` y `push` apuntando a tu repo.

---

## Paso 5 — Subir (push)

### 5a. Caso normal (repo vacío)

```bash
git push -u origin main
```

### 5b. Si el repo ya tenía un README de GitHub

El push se rechaza. Solución:

```bash
git fetch origin
git push -u origin main --force-with-lease
```

Eso reemplaza el README automático por el tuyo.

### Cuando pida credenciales

```text
Username for 'https://github.com': holamecracktino-spec
Password for 'https://holamecracktino-spec@github.com': ghp_...
```

- **Username:** tu usuario de GitHub
- **Password:** el token `ghp_...`
- Al pegar el token **no se ve nada** → es normal, pulsa Enter

Si funciona verás:

```text
branch 'main' set up to track 'origin/main'.
```

---

## Paso 6 — Guardar el token (opcional)

Para que no lo pida cada vez:

```bash
git config --global credential.helper store
```

La próxima vez que pegues el token, quedará guardado en `~/.git-credentials`.

> ⚠️ Se guarda en texto plano en tu celular. No compartas ese archivo.

Si algún día falla la autenticación:

```bash
rm -f ~/.git-credentials
git push
```

---

## Paso 7 — Verificar

```bash
git status -sb
```

Correcto:

```text
## main...origin/main
```

Mal (aún sin subir):

```text
## main...origin/main [ahead 1]
```

Comprobar remoto y descarga pública:

```bash
git ls-remote origin main
curl -fsSI https://raw.githubusercontent.com/holamecracktino-spec/MR.Robottico_facil/main/MR.Robottico_facil.sh | head -1
```

Debe dar `HTTP/2 200`.

Abre el repo:

👉 **https://github.com/holamecracktino-spec/MR.Robottico_facil**

---

## Paso 8 — Actualizar en el futuro

Cada vez que cambies algo:

```bash
cd ~/mr_robottico_facil
git add -A
git commit -m "descripción del cambio"
git push
```

O con el helper del proyecto:

```bash
./subir.sh holamecracktino-spec
```

---

## 🧯 Problemas comunes

| Mensaje | Causa | Solución |
|---|---|---|
| `Note has already been taken` | Ya existe un token con ese nombre | Cambia el nombre del token |
| `Authentication failed` | Token mal copiado o sin scope `repo` | Genera otro token y verifica `repo` |
| `Repository not found` | URL o nombre mal escrito | Revisa `git remote -v` |
| `Updates were rejected` | El remoto tiene commits que no tienes | `git fetch origin` + `git push --force-with-lease` |
| `stale info` | El remoto cambió desde tu fetch | `git fetch origin` y repite el push |
| `Not Found` en el navegador | URL partida o con espacio | Cópiala en una sola línea |
| Pide token siempre | No hay credential helper | `git config --global credential.helper store` |
| Perdiste el token | Solo se muestra una vez | Genera uno nuevo en `/settings/tokens` |

---

## 📋 Resumen en 6 comandos

```bash
cd ~/mr_robottico_facil
git init -b main
git add -A && git commit -m "primer commit"
git remote add origin https://github.com/holamecracktino-spec/MR.Robottico_facil.git
git push -u origin main        # usuario + token
git status -sb                 # verificar
```
