#!/bin/bash

SCRIPTPATH=`dirname $0`;

. $SCRIPTPATH/config.sh

#wait until it's down
echo "Waiting for jackrabbit with PID $JRPID to shut down";
kill $JRPID
while kill -0 $JRPID 2> /dev/null
do
echo -n "."
sleep 1
done
echo ".";
echo "Jackrabbit is down"
echo "Copy the whole repository location with rsync";
rsync -avr $REPOLOCATION/ $REPOLOCATION.bkup

echo "Get JOURNAL_ID"

JRCLUSTERID=`xsltproc  $SCRIPTPATH/getClusterId.xsl $REPOLOCATION.bkup/repository.xml` 

echo "Found JOURNAL_ID: $JRCLUSTERID"

echo "Get LOCAL_REVISION ID from mysql"
ID=`$MYSQLBIN -u $MYSQLUSER -h $MYSQLHOST -p$MYSQLPASS $MYSQLDB --silent -N -e "select REVISION_ID from JOURNAL_LOCAL_REVISIONS where JOURNAL_ID = '$JRCLUSTERID'"`
if [[ -z $ID ]]
then
 echo "****"
 echo "No revision id for '$JRCLUSTERID' found. Please make sure this is in the database"
 echo "We stop here and start Jackrabbit again";
 echo "****"
 $JRSTART &
 exit 1;
fi
echo "It's $ID, write this to $REPOLOCATION.bkup/current_revision_id.dat"
echo $ID > $REPOLOCATION.bkup/current_revision_id.dat
echo "Adjust clusterconfig of $REPOLOCATION.bkup/repository.xml"
xsltproc --nonet --param cluster_id "'$JRCLUSTERID_NEW'" $SCRIPTPATH/changeClusterId.xsl $REPOLOCATION.bkup/repository.xml > $REPOLOCATION.bkup/repository.xml.new 2> /dev/null
mv $REPOLOCATION.bkup/repository.xml.new $REPOLOCATION.bkup/repository.xml
echo "Start Jackrabbit again"
$JRSTART &
echo "***"
echo "Now move $REPOLOCATION.bkup to your new location"
echo "***"
