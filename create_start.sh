#!/bin/bash
if [ -f provision_check ]; then
    echo "container has been provisioned"
    cd /home/trac/src
    tracd --port 8000 ./project
    exit 0
fi

################################################################################
#plugins
echo 
echo "Install plugins"
echo 
echo "  Install fullplogplugin"
echo 
cd /tmp
svn export http://svn.osdn.jp/svnroot/shibuya-trac/plugins/ganttcalendarplugin/trunk
cd trunk;python setup.py bdist_egg;easy_install dist/*.egg;cd /tmp
rm -rf /tmp/trunk
#fullblogplugin
echo 
echo "  Install fullplogplugin"
echo 
easy_install --always-unzip https://trac-hacks.org/svn/fullblogplugin/0.11
#markdown
echo 
echo "  Install markdown"
echo 
easy_install markdown2
easy_install https://github.com/alexdo/trac-markdown-processor/zipball/master
#plantuml
echo 
echo "  Install plantuml"
echo 
easy_install https://trac-hacks.org/svn/plantumlmacro/trunk
#syntax
echo 
echo "  Install syntax"
echo 
easy_install pygments
#plugins
################################################################################

if [ -d /home/trac/src/project ]; then
    if [ -f /home/trac/backup/postgres-db-backup.sql.gz ]; then
        echo "trac-env:project exists"
        set PGPASSWORD=tracpwd
        cd /home/trac/backup
        #dropdb -h postgres -U trac tracdb < tracpwd
        #createdb -h postgres -U trac tracd < tracpwd
        gzip -d postgres-db-backup.sql.gz;
        psql -U trac -d tracdb -h postgres -f postgres-db-backup.sql < tracpwd

        cd /home/trac/src
        tracd --port 8000 ./project
        exit 0
    fi
fi

rm -rf /home/trac/backup/*
rm -rf /home/trac/src/*
cd /home/trac/src

echo "container has not been provisioned, install ..."
touch provision_check
#sleep 10
trac-admin ./project initenv "Project" postgres://trac:tracpwd@postgres/tracdb?client_encoding=utf8
trac-admin ./project permission add anonymous TRAC_ADMIN
cp /home/trac/logo.png ./project/htdocs/your_project_logo.png

##plugins
#cd /tmp
#svn export http://svn.osdn.jp/svnroot/shibuya-trac/plugins/ganttcalendarplugin/trunk
#cd trunk;python setup.py bdist_egg;easy_install dist/*.egg
#cd /home/trac/src/project/conf
#rm -rf /tmp/trunk


#edit trac.ini
cd /home/trac/src/project/conf
#https://trac-hacks.org/wiki/GanttCalendarPlugin
/usr/local/bin/edit_ini.py trac.ini add components ganttcalendar.admin.holidayadminpanel enabled
/usr/local/bin/edit_ini.py trac.ini add components ganttcalendar.complete_by_close.completeticketobserver  enabled
/usr/local/bin/edit_ini.py trac.ini add components ganttcalendar.ticketcalendar.ticketcalendarplugin  enabled
/usr/local/bin/edit_ini.py trac.ini add components ganttcalendar.ticketgantt.ticketganttchartplugin  enabled
/usr/local/bin/edit_ini.py trac.ini add components ganttcalendar.ticketvalidator.ticketvalidator  enabled

/usr/local/bin/edit_ini.py trac.ini add mainnav ticketgantt.label "Ticket Gantt"
/usr/local/bin/edit_ini.py trac.ini add mainnav ticketcalendar.label "Ticket Calendar"

/usr/local/bin/edit_ini.py trac.ini add ticket-custom complete select
/usr/local/bin/edit_ini.py trac.ini add ticket-custom complete.label "Completed [%%]"
sed -i -r 's/complete\.label\ =\ Completed\ \[%%\]/complete\.label\ =\ Completed \[%\]/' trac.ini
/usr/local/bin/edit_ini.py trac.ini add ticket-custom complete.options "|0|5|10|15|20|25|30|35|40|45|50|55|60|65|70|75|80|85|90|95|100"

/usr/local/bin/edit_ini.py trac.ini add ticket-custom complete.order 3
/usr/local/bin/edit_ini.py trac.ini add ticket-custom due_assign text
/usr/local/bin/edit_ini.py trac.ini add ticket-custom due_assign.label "Start (YYYY-MM-DD)"
/usr/local/bin/edit_ini.py trac.ini add ticket-custom due_assign.order 1
/usr/local/bin/edit_ini.py trac.ini add ticket-custom due_close text
/usr/local/bin/edit_ini.py trac.ini add ticket-custom due_close.label "End (YYYY-MM-DD)"
/usr/local/bin/edit_ini.py trac.ini add ticket-custom due_close.order 2

/usr/local/bin/edit_ini.py trac.ini add ganttcalendar complete_conditions "fixed, invalid"
/usr/local/bin/edit_ini.py trac.ini add ganttcalendar default_zoom_mode 1
/usr/local/bin/edit_ini.py trac.ini add ganttcalendar first_day 0
/usr/local/bin/edit_ini.py trac.ini add ganttcalendar format "%%Y-%%m-%%d"
sed -i -r 's/format\ =\ %%Y-%%m-%%d/format\ =\ %Y-%m-%d/' trac.ini
/usr/local/bin/edit_ini.py trac.ini add ganttcalendar show_ticket_summary "false"
/usr/local/bin/edit_ini.py trac.ini add ganttcalendar show_weekly_view "false"

#fullblogplugin
#move above
#easy_install --always-unzip https://trac-hacks.org/svn/fullblogplugin/0.11
/usr/local/bin/edit_ini.py trac.ini add components "tracfullblog.*" enabled
/usr/local/bin/edit_ini.py trac.ini add mainnav "blog.order" 1.5
/usr/local/bin/edit_ini.py trac.ini add fullblog default_postname "%%Y/%%m/%%d/%%H-%%M"
sed -i -r 's/default_postname\ =\ %%Y\/%%m\/%%d\/%%H-%%M/default_postname\ =\ %Y\/%m\/%d\/%H-%M/' trac.ini
/usr/local/bin/edit_ini.py trac.ini add fullblog num_items_front 20
/usr/local/bin/edit_ini.py trac.ini add trac mainnav "wiki, blog, timeline, roadmap, browser, tickets, newticket, search"

#upgrade
cd /home/trac/src
echo "[Docker] ready to upgrade trac"
trac-admin /home/trac/src/project upgrade --no-backup
trac-admin /home/trac/src/project wiki upgrade
echo "[Docker] upgrade trac done"
cd /home/trac/src/project/conf

echo "[Docker] modify trac.ini config"
#markdown
#move above
#easy_install markdown2
#easy_install https://github.com/alexdo/trac-markdown-processor/zipball/master
/usr/local/bin/edit_ini.py trac.ini add components "markdown.processor.*" enabled

#plantuml
##wget http://downloads.sourceforge.net/project/plantuml/plantuml.jar
##wget http://sourceforge.net/projects/plantuml/files/plantuml.jar/download -O plantuml.jar
#move above
#easy_install https://trac-hacks.org/svn/plantumlmacro/trunk
/usr/local/bin/edit_ini.py trac.ini add components "plantuml.*" enabled
/usr/local/bin/edit_ini.py trac.ini add plantuml plantuml_jar "/home/trac/plantuml.jar"
/usr/local/bin/edit_ini.py trac.ini add plantuml java_bin "/opt/jdk1.8.0_91/bin/java"

#git
/usr/local/bin/edit_ini.py trac.ini add components "tracopt.versioncontrol.git.*" enabled
/usr/local/bin/edit_ini.py trac.ini add versioncontrol "allowed_repository_dir_prefixes" "/git"
/usr/local/bin/edit_ini.py trac.ini add versioncontrol default_repository_type git
echo "[Docker] modify trac.ini config done"

#syntax
#move above
#easy_install pygments

cd /home/trac/src
tracd --port 8000 ./project

