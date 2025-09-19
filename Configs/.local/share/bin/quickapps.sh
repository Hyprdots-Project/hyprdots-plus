#!/usr/bin/env sh

# set variables
scrDir=`dirname "$(realpath "$0")"`
source $scrDir/globalcontrol.sh
roconf="~/.config/rofi/quickapps.rasi"

if [ $# -eq 0 ] ; then
    echo "usage: ./quickapps.sh <app1> <app2> ... <app[n]>"
    exit 1
else
    appCount="$#"
fi

# set position
if [ ${${cursorPosition[0]}} -le $(( ${monitorResolution[0]}/3 )) ] ; then
    x_rofi="west"
    x_offset="x-offset: 20px;"
elif [ ${${cursorPosition[0]}} -ge $(( ${monitorResolution[0]}/3*2 )) ] ; then
    x_rofi="east"
    x_offset="x-offset: -20px;"
else
    unset x_rofi
fi

if [ ${${cursorPosition[1]}} -le $(( ${monitorResolution[1]}/3 )) ] ; then
    y_rofi="north"
    y_offset="y-offset: 20px;"
elif [ ${${cursorPosition[1]}} -ge $(( ${monitorResolution[1]}/3*2 )) ] ; then
    y_rofi="south"
    y_offset="y-offset: -20px;"
else
    unset y_rofi
fi

if [ ! -z $x_rofi ] || [ ! -z $y_rofi ] ; then
    pos="window {location: $y_rofi $x_rofi; $x_offset $y_offset}"
fi

# override rofi
dockHeight=$(( ${monitorResolution[0]} * 3 / 100))
dockWidth=$(( dockHeight * appCount ))
iconSize=$(( dockHeight - 4 ))
wind_border=$(( hypr_border * 3/2 ))
r_override="window{height:${dockHeight};width:${dockWidth};border-radius:${wind_border}px;} listview{columns:${appCount};} element{border-radius:${wind_border}px;} element-icon{size:${iconSize}px;}"


# launch rofi menu
if [ -d /run/current-system/sw/share/applications ]; then
    appDir=/run/current-system/sw/share/applications
else
    appDir=/usr/share/applications
fi

RofiSel=$( for qapp in "$@"
do
    Lkp=`grep "$qapp" $appDir/* | grep 'Exec=' | awk -F ':' '{print $1}' | head -1`
    Ico=`grep 'Icon=' $Lkp | awk -F '=' '{print $2}' | head -1`
    echo -en "${qapp}\x00icon\x1f${Ico}\n"
done | rofi -no-fixed-num-lines -dmenu -theme-str "${r_override}" -theme-str "${pos}" -config $roconf)

$RofiSel &