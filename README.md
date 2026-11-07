# MR.ROBOTTICO · HTB FÁCIL

Menú de **un solo archivo** para la comunidad de **Termux**: máquinas
**Very Easy** de Hack The Box (Starting Point Tier 0–2 + algunas retiradas Easy).

No necesita instalación, ni carpetas, ni dependencias de Python: es un `.sh`
autocontenido que puedes copiar, compartir y ejecutar en Termux o Linux.

> **Aviso:** material de estudio. Úsalo solo contra máquinas de Hack The Box o
> sistemas propios. Atacar sistemas ajenos sin permiso es ilegal.

---

## Instalación rápida (GitHub)

> Enlaces listos para el usuario `holamecracktino-spec`.

**Clonar el repo:**

```bash
git clone https://github.com/holamecracktino-spec/MR.Robottico_facil.git
cd MR.Robottico_facil
chmod +x MR.Robottico_facil.sh
./MR.Robottico_facil.sh
```

**Solo el script con curl:**

```bash
curl -fsSL https://raw.githubusercontent.com/holamecracktino-spec/MR.Robottico_facil/main/MR.Robottico_facil.sh -o MR.Robottico_facil.sh
chmod +x MR.Robottico_facil.sh
./MR.Robottico_facil.sh
```

**Solo el script con wget:**

```bash
wget -qO MR.Robottico_facil.sh https://raw.githubusercontent.com/holamecracktino-spec/MR.Robottico_facil/main/MR.Robottico_facil.sh
chmod +x MR.Robottico_facil.sh
./MR.Robottico_facil.sh
```

> No ejecutes `curl ... | bash` con scripts de fuentes que no controlas:
> descárgalo, léelo y luego ejecútalo.

---

## Ejecutar

```bash
chmod +x MR.Robottico_facil.sh
./MR.Robottico_facil.sh
```

O sin permisos:

```bash
bash MR.Robottico_facil.sh
```

### Opciones

```bash
./MR.Robottico_facil.sh -h                 # ayuda
./MR.Robottico_facil.sh -l                 # lista las 19 máquinas
./MR.Robottico_facil.sh -t 10.10.10.5      # fija la IP objetivo
./MR.Robottico_facil.sh -m meow -p         # pistas de Meow
./MR.Robottico_facil.sh -m meow -q         # reto: preguntas + flag
./MR.Robottico_facil.sh -m dancing -r -t IP          # recon (pregunta)
./MR.Robottico_facil.sh -m dancing -r -t IP -y       # recon sin preguntar
```

Dentro del menú de una máquina:

| Opción | Acción |
|---|---|
| `1` | Recon automatizado (nmap + servicio) |
| `2` | Pistas / pasos manuales |
| `3` | **Reto**: preguntas y al final la flag |
| `4` | Todo |
| `5` | Notas (se guardan en `notas/<id>.md`) |
| `6` | Cambiar IP objetivo |

En el menú principal: `[H]` herramientas/Termux, `[P]` progreso, `[0]` salir.

### Modo reto

Cada máquina tiene 3 preguntas con opciones (la correcta cambia de posición
cada vez): qué servicio atacar, qué herramienta usar, qué ataque o escalada
aplica. Al terminar te muestra los aciertos y te pide la **flag**.

- La flag se guarda en `notas/<id>.md` y la máquina se marca en `progreso.md`.
- Puedes saltarte la flag con Enter.
- `[P]` en el menú principal muestra tu progreso y las flags guardadas.

Los comandos se muestran **antes** de ejecutarse y piden `y/N`.

---

## Máquinas

| # | Máquina | Tier | OS | Tema |
|---|---|---|---|---|
| 1 | Meow | SP · Tier 0 | Linux | Telnet sin auth |
| 2 | Fawn | SP · Tier 0 | Linux | FTP anónimo |
| 3 | Dancing | SP · Tier 0 | Windows | SMB null session |
| 4 | Redeemer | SP · Tier 0 | Linux | Redis sin auth |
| 5 | Appointment | SP · Tier 1 | Linux | SQLi / bypass login |
| 6 | Sequel | SP · Tier 1 | Linux | MySQL root sin pass |
| 7 | Crocodile | SP · Tier 1 | Linux | FTP + web + upload |
| 8 | Responder | SP · Tier 1 | Windows | NTLM / Responder |
| 9 | Three | SP · Tier 1 | Linux | Bucket S3 / MinIO |
| 10 | Ignition | SP · Tier 1 | Linux | Magento / creds default |
| 11 | Archetype | SP · Tier 2 | Windows | SMB + MSSQL + psexec |
| 12 | Oopsie | SP · Tier 2 | Linux | Upload + SUID + PATH |
| 13 | Vaccine | SP · Tier 2 | Linux | FTP + zip + SQLi + sudo vi |
| 14 | Unified | SP · Tier 2 | Linux | Log4Shell |
| 15 | Jerry | Retirada · Easy | Windows | Tomcat manager + WAR |
| 16 | Blue | Retirada · Easy | Windows | MS17-010 EternalBlue |
| 17 | Buff | Retirada · Easy | Windows | Upload + CloudMe |
| 18 | Netmon | Retirada · Easy | Windows | FTP + PRTG RCE |
| 19 | Devel | Retirada · Easy | Windows | FTP escribible + aspx |

---

## Termux

Lo básico:

```bash
pkg install nmap netcat-openbsd curl wget git nano
```

Para `smbclient`, `impacket`, `responder`, `sqlmap` o Metasploit:

```bash
pkg install proot-distro
proot-distro install kali
proot-distro login kali
```

Dentro de Kali: `apt install smbclient sqlmap metasploit-framework`.

**Dominios sin root:** Termux no puede editar `/etc/hosts`, usa:

```bash
curl --resolve unika.htb:80:10.10.10.5 http://unika.htb/
```

La opción `[H] Herramientas / Termux` del menú tiene la chuleta completa.

---

## Añadir una máquina

Todo está en el mismo archivo. Añade tres cosas:

1. La línea `add` en el bloque de metadatos:

```bash
add mimquina "MiMaquina" "Retirada · Easy" "Linux" "Easy" "80/tcp" "web · upload"
```

2. Sus dos funciones:

```bash
rm_mimaquina_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
}

rm_mimaquina_pistas() {
  msg "MiMaquina — pista general"
  pista "Paso 1..."
  paso "curl -s http://$RHOST/"
}
```

3. Nada más: el menú la detecta automáticamente.

Variables disponibles: `$RHOST` (IP objetivo), `$AUTO`, `$(lhost)`, y los helpers
`necesita`, `ejecutar`, `pista`, `paso`, `msg`, `ok`, `aviso`, `error`, `tenue`.

---

## Publicar en GitHub

1. Crea el repositorio **vacío** en <https://github.com/new> (sin README ni
   licencia, porque ya están en el proyecto).
2. Desde Termux:

```bash
cd mr_robottico_facil
chmod +x subir.sh
./subir.sh holamecracktino-spec
```

Te pedirá usuario y contraseña: en la contraseña pega un **Personal Access
Token (PAT)** con permiso `repo`, no tu contraseña normal.

3. Cuando cambies algo:

```bash
./subir.sh holamecracktino-spec
```

El `.gitignore` excluye `notas/` y `progreso.md`, así que tus flags personales
no se suben al repositorio.

---

## Créditos

Estilo y nombre inspirados en **MR.ROBOTTICO** (menú de OverTheWire).
Hecho para compartir en la comunidad de Termux. Si lo mejoras, comparte el
archivo: es autocontenido a propósito.
