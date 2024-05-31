#!/system/bin/sh
INDLOG="/sdcard/#INDRA/Logs/menu.log"
exec 2>>"$INDLOG"

# Read Files (Without Space)
READ() {
  value=$(sed -e '/^[[:blank:]]*#/d;s/[\t\n\r ]//g;/^$/d' "$2" | grep -m 1 "^$1=" | cut -d'=' -f 2)
  echo "$value"
  return $?
}

# Read Files (With Space)
READS() {
  value=$(grep -m 1 "^$1=" "$2" | sed 's/^.*=//')
  echo "${value//[[:space:]]/ }"
}

# Indra's Logs
ind () {
    if [ "$1" = "Exclude" ]; then
      exec 2>/dev/null;
    else
      echo "" >> "$INDLOG"
      echo "# $1 - [$(date)]" >> "$INDLOG"
      exec 2>>"$INDLOG" 
    fi
}

# Indra's Comments  
indc () {
  if [ -n "$1" ]; then
    echo -e "$1"
    echo ""
  fi
}

# Write Function
write() {
 [[ ! -f "$1" ]] && return 1
 chmod +w "$1" 2> /dev/null
 if ! echo "$2" > "$1"   2> /dev/null
 then
  return 1  
 fi
}

# Defines Directories 
MODPATH="/data/adb/modules/indra-vesh"
DB=/data/INDRA
BLSRT=$DB/BLScripts
CFSRT=$DB/CFScripts
SRT=$DB/Scripts
CONF=$DB/Configs
BLC=$CONF/blc.txt
CFC=$CONF/cfc.txt
CFGC=$CONF/cfgc.txt
CYOM="$DB/Magic Kit/CYOM"
MOD="$CYOM/Module"
ROOTDIR=/data/adb/modules
MERGE="$DB/Magic Kit/MERGE"
MODPACK="$MERGE/ModPack"
UPC=$CONF/upc.txt

# Check A/B slot
if [[ -d /system_root ]]; then
  isABDevice=true
  SYSTEM=/system_root/system
  SYSTEM2=/system
  CACHELOC=/data/cache
else
  isABDevice=false
  SYSTEM=/system
  SYSTEM2=/system
  CACHELOC=/cache
fi
[[ -z "$isABDevice" ]] && { echo " ❌ Something went wrong"; exit 1; }

# Set perm
set_perm() {
  chown "$2":"$3" "$1" || return 1
  chmod "$4" "$1" || return 1
  (if [[ -z "$5" ]]; then
    case $1 in
      *"system/vendor/app/"*) chcon 'u:object_r:vendor_app_file:s0' "$1";;
      *"system/vendor/etc/"*) chcon 'u:object_r:vendor_configs_file:s0' "$1";;
      *"system/vendor/overlay/"*) chcon 'u:object_r:vendor_overlay_file:s0' "$1";;
      *"system/vendor/"*) chcon 'u:object_r:vendor_file:s0' "$1";;
      *) chcon 'u:object_r:system_file:s0' "$1";;
    esac
  else
    chcon "$5" "$1"
  fi) || return 1
}

# Set perm recursive
set_perm_recursive() {
  find "$1" -type d 2>/dev/null | while read dir; do
    set_perm "$dir" "$2" "$3" "$4" "$6"
  done
  find "$1" -type f -o -type l 2>/dev/null | while read file; do
    set_perm "$file" "$2" "$3" "$5" "$6"
  done
}

# Mktouch
mktouch() {
  mkdir -p "${1%/*}" 2>/dev/null
  [[ -z $2 ]] && touch "$1" || echo "$2" > "$1"
  chmod 644 "$1"
}

# Grep prop
grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [[ -z "$FILES" ]] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

# Is mounted
is_mounted() {
  grep -q " $(readlink -f "$1") " /proc/mounts 2>/dev/null
  return $?
}


# Abort
abort() {
  echo "$1"
  exit 1
}

# Device Info
# Variables: BRAND MODEL DEVICE API ABI ABI2 ABILONG ARCH
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
API=$(grep_prop ro.build.version.sdk)
ABI=$(grep_prop ro.product.cpu.abi | cut -c-3)
ABI2=$(grep_prop ro.product.cpu.abi2 | cut -c-3)
ABILONG=$(grep_prop ro.product.cpu.abi)
ARCH=arm
ARCH32=arm
IS64BIT=false
if [[ "$ABI" = "x86" ]]; then ARCH=x86; ARCH32=x86; fi;
if [[ "$ABI2" = "x86" ]]; then ARCH=x86; ARCH32=x86; fi;
if [[ "$ABILONG" = "arm64-v8a" ]]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
if [[ "$ABILONG" = "x86_64" ]]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
  
# Defines
VER=$(READ version "$MODPATH"/module.prop)
REL=$(READ versionCode "$MODPATH"/module.prop)
AUTHOR=$(READS author "$MODPATH"/module.prop)
MODT=$(READS name "$MODPATH"/module.prop)

# Colors
G='\e[01;32m'		# GREEN TEXT
R='\e[01;31m'		# RED TEXT
Y='\e[01;33m'		# YELLOW TEXT
B='\e[01;34m'		# BLUE TEXT
V='\e[01;35m'		# VIOLET TEXT
Bl='\e[01;30m'		# BLACK TEXT
C='\e[01;36m'		# CYAN TEXT
W='\e[01;37m'		# WHITE TEXT
BGBL='\e[1;30;47m'	# Background W Text Bl
N='\e[0m'			# How to use (example): echo "${G}example${N}"
loadBar=' '			# Load UI
# Remove color codes if -nc or in ADB Shell
[[ -n "$1" ]] && [[ "$1" = "-nc" ]] && shift && NC=true
[[ "$NC" ]] || [[ -n "$ANDROID_SOCKET_adbd" ]] && {
  G=''; R=''; Y=''; B=''; V=''; Bl=''; C=''; W=''; N=''; BGBL=''; loadBar='=';
}

# No. of characters in $MODTITLE, $VER, and $REL
character_no=$(echo "$MODTITLE $VER $REL" | wc -c)

# Divider
div="${Bl}$(printf '%*s' "${character_no}" '' | tr " " "=")${N}"

# title_div [-c] <title>
# based on $div with <title>
title_div() {
  [[ "$1" = "-c" ]] && local character_no=$2 && shift 2
  [[ -z "$1" ]] && { local message=; no=0; } || { local message="$@ "; local no=$(echo "$@" | wc -c); }
  [[ $character_no -gt $no ]] && local extdiv=$((character_no-no)) || { echo "Invalid!"; return 1; }
  echo "${W}$message${N}${Bl}$(printf '%*s' "$extdiv" '' | tr " " "=")${N}"
}

# set_file_prop <property> <value> <prop.file>
set_file_prop() {
  if [[ -f "$3" ]]; then
    if grep -q "$1=" "$3"; then
      sed -i "s/${1}=.*/${1}=${2}/g" "$3"
    else
      echo "$1=$2" >> "$3"
    fi
  else
    echo "- $3 doesn't exist"; return 1
  fi
}

# Check which Rooting Tool were used to Root Mobile
if [ -d "/data/adb/magisk" ] && magisk -V >/dev/null 2&>1 || magisk -v >/dev/null 2&>1; then
ROOT="Magisk"
elif [ -d "/data/adb/ksu" ] && ksud -V >/dev/null 2&>1 || ksud -v >/dev/null 2&>1; then
ROOT="KSU"
elif [ -d "/data/adb/ap" ] && apd -V >/dev/null 2&>1 || apd -v >/dev/null 2&>1; then
ROOT="APatch"
else
ROOT="INVALID, Contact @ShastikXD On Telegram"
fi

# Check for Internet Connection
test_net() {
if timeout 5 ping -q -c 1 -W 1 google.com >/dev/null 2>&1; then
    CONNECTION="${G}Online"
    NET="ON"
else
    CONNECTION="${R}Offline"
    NET="OFF"
fi
}

# ProgressBar <progress> <total>
ProgressBar() {
# Determine Screen Size
  if [[ "$COLUMNS" -le "57" ]]; then
    local var1=2
	local var2=20
  else
    local var1=4
    local var2=40
  fi
# Process data
  local _progress=$(((${1}*100/${2}*100)/100))
  local _done=$(((${_progress}*${var1})/10))
  local _left=$((${var2}-$_done))
# Build progressbar string lengths
  local _done=$(printf "%${_done}s")
  local _left=$(printf "%${_left}s")

# Build progressbar strings and print the ProgressBar line
printf "\rProgress : ${BGBL}|${N}${_done// /${BGBL}$loadBar${N}}${_left// / }${BGBL}|${N} ${_progress}%%"
}

# Downloading any File and Displaying progress using Progress Bar
# Download <url> <filepath/filename>
Download() {
local url=$1
local filepath=$2
test_net
if [ "$NET" = "ON" ]; then
online_size=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '')
touch "$filepath" 
local_size=$(stat -c %s "$filepath")
curl -L "$url" -o "$filepath" > /dev/null 2>&1 &
while [ "$local_size" -lt "$online_size" ]; do
local_size=$(stat -c %s "$filepath")
ProgressBar "$local_size" "$online_size"
sleep 1
done
printf "\033c"
else
   indc "${R} ✖ Internet is not working, Please check your internet connection. ${N}"
sleep 3
indra
exit
fi
}

# Function to turn on or off Toggle Control Options
Turn() {
local bool=$1
local value=$2
local file=$3
local id=$4
local name=$5
sed -i "/$value/s/.*/$value=$bool/" $file
ind "Turning $bool $name"
source $BLSRT/$id.sh
}