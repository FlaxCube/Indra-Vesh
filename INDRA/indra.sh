#!/system/bin/sh

# Menu
Menu() {
    echo -e '\n'
    printf "\033c"
    test_net 
    indc "${C} ✦✧✦✧✦✧✦✧✦✧ Indra Vesh - Command Center ✧✦✧✦✧✦✧✦✧✦ ${N}"
    indc "${W} ✶ Welcome to Indra-Vesh - Menu ${N}"
    indc "${W} ✶ Created & Written By @ShastikXD ${N}"
    indc "${W} ✶ Version = ${C}$VER ${N}"
    indc "${W} ✶ Tool Used for Rooting = ${B}$ROOT ${N}"
    indc "${W} ✶ Internet = $CONNECTION ${N}"
    indc "${Y} ✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦ ${N}"
    indc "${W} ❐ [1] Toggle Control ${N}"
    indc "${W} ❐ [2] Tune Dynamics ${N}"
    indc "${W} ❐ [3] Magic Kit ${N}"
    indc "${W} ❐ [4] Configuration ${N}"
    indc "${W} ❐ [5] Updater ${N}"
    indc "${R} ✖ [0] Exit ${N}"
    indc "${Y} ✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦ ${N}"
    indc "${C} ✷ Enter Number Respective to its Menu:  ${N}"
    read option
    case $option in
        1) Option1 ;;
        2) Option2 ;;
        3) Option3 ;;
        4) Option4 ;;
        5) Option5 ;;
        0) GoOut ;;
        *) Menu ;;
    esac    
    }

Option1 () {
    printf "\033c"
    ind "# Opening Toggle Control Menu"
    . $DB/Scripts/bls.sh
}

Option2 () {
    printf "\033c"
    ind "# Opening Tune Dynamics Menu"
    . $DB/Scripts/cfs.sh
}

Option3 () {
    printf "\033c"
    ind "# Opening Magic Kit Menu"
    . $DB/Scripts/mks.sh
}

Option4 () {
    printf "\033c"
    ind "# Opening Configuration Menu"
    . $DB/Scripts/cfgs.sh
}

Option5 () {
    printf "\033c"
    ind "# Opening Updater Menu"
    . $DB/Scripts/upd.sh
}

Reboot() {
    printf "\033c"
    reboot system
    printf "\033c"
}

GoOut() {
    printf "\033c"
    ind "${G} 👋 All Done, See You next Time.${N}"
    exit
}

printf "\033c"
Menu