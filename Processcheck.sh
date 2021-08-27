wh=$(grep -A1 'checktool:' /home/Bathin1p/rao/yml/config.yml | tail -n1 | awk '{print $2}')
echo $wh


ip=$(grep -A1 'proxy:' /home/Bathin1p/rao/yml/config.yml | tail -n1 | awk '{print $2}')
echo $ip

port=$(grep -A2 'proxy:' /home/Bathin1p/rao/yml/config.yml | tail -n1 | awk '{print $2}')

echo $port
[Bathin1p@devqa-bastion yml]$ clear
[Bathin1p@devqa-bastion yml]$ als
-bash: als: command not found
[Bathin1p@devqa-bastion yml]$ ls
checktool.sh  checktool.sh_bkp  config.yml  test.sh
[Bathin1p@devqa-bastion yml]$ cat checktool.sh
#!/bin/bashAdimul1S
CHECKTOOL=/var/checktool
SNAPSHOTFILE=snapshot.txt
EXCEPTION=exception.txt
HOST=$(hostname)
hostip=$(hostname -I | awk '{print $1}')
wh=$(grep -A1 'checktool:' /home/Bathin1p/rao/yml/config.yml | tail -n1 | awk '{print $2}')
proxyip=$(grep -A1 'proxy:' /home/Bathin1p/rao/yml/config.yml | tail -n1 | awk '{print $2}')
proxyport=$(grep -A2 'proxy:' /home/Bathin1p/rao/yml/config.yml | tail -n1 | awk '{print $2}')

function snapshot()
{
        sudo mkdir $CHECKTOOL
        sudo chown -R $(id -u):$(id -g) $CHECKTOOL
        printf '\xEF\xBB\xBF' > $CHECKTOOL/$SNAPSHOTFILE
        ps -ef >> $CHECKTOOL/$SNAPSHOTFILE
        sed -i '1 i\IP: '$hostip'' $CHECKTOOL/$SNAPSHOTFILE
        sed -i '1 i\HOST: '$HOST'' $CHECKTOOL/$SNAPSHOTFILE
        sed -i '1 i\Got a Snapshot.' $CHECKTOOL/$SNAPSHOTFILE
        #       prodata=$(cat $CHECKTOOL/$SNAPSHOTFILE)
        #       curl -x $proxyip:$proxyport -X POST -H 'Content-type: application/json' --data '{"text":"'"$prodata"'"}' $wh
        ps -axo cmd > $CHECKTOOL/filter_$SNAPSHOTFILE
        sed '1d' $CHECKTOOL/filter_$SNAPSHOTFILE > $CHECKTOOL/temp
        sort $CHECKTOOL/temp |uniq > $CHECKTOOL/filter_$SNAPSHOTFILE
}

function untrusted()
{
        echo "alert.txt file is not empty"
        echo "UNTRUSTED ---" >> $CHECKTOOL/log
        sed -n '4,4p' $CHECKTOOL/$SNAPSHOTFILE >> $CHECKTOOL/log
        while read -r line; do
                grep -i "$line" $CHECKTOOL/New_$SNAPSHOTFILE >> $CHECKTOOL/log
        done <"$i"
}

function missing()
{
         echo "missing_$SNAPSHOTFILE  file is not empty"
         echo "MISSING ---" >> $CHECKTOOL/log
         sed -n '4,4p' $CHECKTOOL/$SNAPSHOTFILE >> $CHECKTOOL/log
         while read -r line; do
                grep -i "$line" $CHECKTOOL/$SNAPSHOTFILE >> $CHECKTOOL/log
         done <"$j"
}

function finallog()
{
        sed -i '1 i\IP: '$hostip'' $CHECKTOOL/log
        sed -i '1 i\HOST: '$HOST'' $CHECKTOOL/log
        sed -i '1 i\Difference detected.' $CHECKTOOL/log
        prodata1=$(cat $CHECKTOOL/log)
        # curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$prodata1"'"}' https://hooks.slack.com/services/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
        # curl -x 10.115.0.199:8888 -X POST -H 'Content-type: application/json' --data '{"text":"'"$prodata1"'"}' https://hooks.slack.com/services/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
}

# Snapshot file chicking in the path if not exist create snpshot file and send slack notification

if [ ! -f "$CHECKTOOL/$SNAPSHOTFILE" ]; then
        snapshot
else

# Provide exception process details
printf '\xEF\xBB\xBF' > $CHECKTOOL/$EXCEPTION
cat <<EOF >> $CHECKTOOL/$EXCEPTION
sshd: Dinesh1K@pts/2
/usr/local/bin/node_exporter
/usr/sbin/crond
/opt/stackdriver/collectd/sbin/stackdriver-collectd -C /etc/stackdriver/collectd.conf -f
EOF

        sort $CHECKTOOL/$EXCEPTION > $CHECKTOOL/temp
        mv $CHECKTOOL/temp $CHECKTOOL/$EXCEPTION

        # Compare snapshot with new process list
        ps -ef > $CHECKTOOL/New_$SNAPSHOTFILE
        ps -axo cmd > $CHECKTOOL/New_filter_$SNAPSHOTFILE
        sed '1d' $CHECKTOOL/New_filter_$SNAPSHOTFILE > $CHECKTOOL/temp
        sort $CHECKTOOL/temp |uniq > $CHECKTOOL/New_filter_$SNAPSHOTFILE
        rm -rf $CHECKTOOL/temp

        diff -w $CHECKTOOL/filter_$SNAPSHOTFILE $CHECKTOOL/New_filter_$SNAPSHOTFILE | grep ">" > $CHECKTOOL/diff_$SNAPSHOTFILE
        diff -w $CHECKTOOL/filter_$SNAPSHOTFILE $CHECKTOOL/New_filter_$SNAPSHOTFILE | grep "<" > $CHECKTOOL/missing_$SNAPSHOTFILE

        sed -i -e 's/>//g' $CHECKTOOL/diff_$SNAPSHOTFILE
        sed 's/^[ \t]*//;s/[ \t]*$//' $CHECKTOOL/diff_$SNAPSHOTFILE > $CHECKTOOL/temp_$SNAPSHOTFILE
        mv $CHECKTOOL/temp_$SNAPSHOTFILE $CHECKTOOL/diff_$SNAPSHOTFILE

        sed -i -e 's/<//g' $CHECKTOOL/missing_$SNAPSHOTFILE
        sed 's/^[ \t]*//;s/[ \t]*$//' $CHECKTOOL/missing_$SNAPSHOTFILE > $CHECKTOOL/temp_$SNAPSHOTFILE
        mv $CHECKTOOL/temp_$SNAPSHOTFILE $CHECKTOOL/missing_$SNAPSHOTFILE
        cat $CHECKTOOL/missing_$SNAPSHOTFILE |sed 's/[][]//g' > $CHECKTOOL/MISSING_$SNAPSHOTFILE
        mv $CHECKTOOL/MISSING_$SNAPSHOTFILE $CHECKTOOL/missing_$SNAPSHOTFILE

        # Compare with exception file
        diff $CHECKTOOL/$EXCEPTION $CHECKTOOL/diff_$SNAPSHOTFILE | grep ">" > $CHECKTOOL/diff_$EXCEPTION
        sed -i -e 's/>//g' $CHECKTOOL/diff_$EXCEPTION
        sed 's/^[ \t]*//;s/[ \t]*$//' $CHECKTOOL/diff_$EXCEPTION > $CHECKTOOL/temp_$EXCEPTION
        mv $CHECKTOOL/temp_$EXCEPTION $CHECKTOOL/diff_$EXCEPTION
        #remove [] in final file
        cat $CHECKTOOL/diff_$EXCEPTION |sed 's/[][]//g' > $CHECKTOOL/alert.txt

        > $CHECKTOOL/log
        i=$CHECKTOOL/alert.txt
        if [ -s $CHECKTOOL/alert.txt ]
        then
                untrusted
        else
                echo "Alert.txt file is empty"
        fi

        j=$CHECKTOOL/missing_$SNAPSHOTFILE
        if [ -s $CHECKTOOL/missing_$SNAPSHOTFILE ]
        then
                missing
        else
                 echo "missing_$SNAPSHOTFILE file is empty"
        fi

        if [ -s $CHECKTOOL/log ]
        then
                finallog
        fi
fi
