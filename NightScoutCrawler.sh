#!/bin/sh

#*******************
#  _____             _                 _______          _     
# |  __ \           | |               |__   __|        | |    
# | |__) |__ _ _ __ | |__   __ _ ___     | | ___   ___ | |___ 
# |  _  // _` | '_ \| '_ \ / _` / __|    | |/ _ \ / _ \| / __|
# | | \ \ (_| | |_) | | | | (_| \__ \    | | (_) | (_) | \__ \
# |_|  \_\__,_| .__/|_| |_|\__,_|___/    |_|\___/ \___/|_|___/
#             | |                                             
#             |_|                                             
#
#*******************
titel="NightScout Crawler"
version="v1.2"
autor="Raphael"
#Aktualisiert:	26.04.2019
#
#*******************
#BESCHREIBUNG:
#	Abholen der Nightscout Werte und Anzeige mit entsprechenden Grenzfarben
#
#	Credits to https://www.hanselman.com/blog/LightingUpMyDasKeyboardWithBloodSugarChangesUsingMyBodysRESTAPI.aspx
#
#*******************
#CHANGELOG:
#
# Neu in v1.2	- Prüfung ob output.txt existiert
# Neu in v1.1	- Filter Datumsanzeige
#
#*******************
#ToDo:
#		- Berechnung Zeit in deutsche Zeit
#		- Wenn Eintrag in output älter 10min, mehere Einträge Abfragen und in output.txt schreiben
#*******************
#Bugs:
#	- Bei erstem Start ist berechnete Differenz == BZ-Wert
#
#*******************
#*******************

set -e 	#quit on first error.

magenta="tput setaf 5"	#Magenta Text für sehr hohen BZ
yellow="tput setaf 3"	#Gelber Text für hohen BZ
green="tput setaf 2"	#Grüner Text für normalen BZ
reset="tput sgr0"		#Zurücksetzen der Formattierung
COLOR="tput setaf 1"	#Roten Text für niedrigen BZ


#Prüfe output.txt
if ! [ -e output.txt ]	
then									
    echo "$titel $version by $autor" >> output.txt	#wenn nicht existiert schreibe Header
fi


#Werte holen
isCurrentEntry=$(curl -s  https://YOURSITEHERE/api/v1/entries.txt?count=1)	#Letzter Onlinewert von Nightscout holen
isEntryLog1=$(tail -n 1 output.txt)				#letzter Eintrag aus output.txt holen
isEntryLog2=$(tail -n 2 output.txt | head -n 1)	#vorletzter Eintrag aus output.txt holen


#Vergleich Werte
if [ "$isCurrentEntry" != "$isEntryLog1" ]	#Wenn Onlinewert ungleich LogEintrag
then
	$(echo "$isCurrentEntry" >> output.txt)	#neuer Wert in output.txt schreiben
	isPreviousEntry=$isEntryLog1
else
	isPreviousEntry=$isEntryLog2
fi


#Filtern der Einträge
isPreviousBG=$(echo $isPreviousEntry | grep -Eo '000\s([0-9]{1,3})+\s' | cut -d ' ' -f2)	#Kürze Variable auf "000 119", Trenne mit " " und nehme 2tes Feld
isPreviousHours=$(echo $isPreviousEntry | grep -Eo '\T+(.)+([.][0]{3})' | cut -c2-3)		#Kürze Variable auf "T13:59:33.000" und schneide Pos 2+3 aus
isPreviousMinutes=$(echo $isPreviousEntry | grep -Eo '\T+(.)+([.][0]{3})' | cut -c5-6)		#Kürze Variable auf "T13:59:33.000" und schneide Pos 5+6 aus

isCurrentBG=$(echo $isCurrentEntry | grep -Eo '000\s([0-9]{1,3})+\s' | cut -d ' ' -f2)
isCurrentHours=$(echo $isCurrentEntry | grep -Eo '\T+(.)+([.][0]{3})' | cut -c2-3)
isCurrentMinutes=$(echo $isCurrentEntry | grep -Eo '\T+(.)+([.][0]{3})' | cut -c5-6)

trend=$(echo $isCurrentEntry | grep -Eo '\s"([a-zA-Z]{4,13})"\s' | cut -d '"' -f2)


#Arithmetische Operationen
#isDifferenceHours=$(( isCurrentHours - isPreviousHours ))
#isDifferenceMinutes=$(( isCurrentMinutes - isPreviousMinutes ))
isDifferenceBG=$(( isCurrentBG - isPreviousBG ))
if [ $isDifferenceBG -ge 0 ]	#Vorzeichen bestimmen
then
	sign="+"	#wenn >= 
fi


#Textfarbe in Abhängigkeit der Grenzen bestimmen
if [ $isCurrentBG -gt 80 ]
then
    COLOR=$green
    if [ $isCurrentBG -gt 200 ]
    then
        COLOR=$yellow
        if [ $isCurrentBG -gt 300 ]
        then
            COLOR=$magenta
        fi
    fi
fi
#alles <80 hat rot: $COLOR

#Trendpfeil aussuchen

case "$trend" in
  DoubleUp)			trend="↑↑"	;;
  SingleUp)			trend="↑"	;;
  FortyFiveUp)		trend="↗"	;;
  Flat)				trend="→"	;;
  FortyFiveDown)	trend="↘"	;;
  SingleDown)		trend="↓"	;;
  DoubleDown)		trend="↓↓"	;;
esac

echo "Wert um $isCurrentHours:$isCurrentMinutes ist $($COLOR)$isCurrentBG$($reset)$trend $sign$isDifferenceBG"
