#!/bin/bash

# Minimum Viable ElasticSearch Graphite 
# David Lutz 2012-10-19
# run with argument elasticsearchserver
# requires ruby gem jgrep
# run from cron like this
# */5	*	*	*	*	/opt/mvesgraphite/mvesg.sh elasticsearchserver  | nc -w 20 your.graphite.server 2003

eshost=$1
friendlyhost=`echo $eshost | sed 's/\./_/g'`

now=`date -u +"%s"`
INFOFILE=`mktemp /tmp/mvesg.$friendlyhost.XXXXXX`
/usr/bin/time --output=$INFOFILE.time --append -f "\n%e" curl "http://$eshost:9200/_nodes/_local/stats/?all=true&pretty=true"  > $INFOFILE

responsetime=`cat $INFOFILE.time | tail -n 1`
echo "elasticsearch.$friendlyhost.responsetime $responsetime $now" 

for i in indices.docs.count indices.docs.deleted indices.store.size_in_bytes indices.indexing.index_total jvm.threads.count network.tcp.curr_estab http.total_opened thread_pool.search.active thread_pool.search.threads indices.cache.filter_size_in_bytes indices.cache.field_size_in_bytes indices.cache.filter_count jvm.mem.heap_used_in_bytes jvm.mem.non_heap_used_in_bytes
do

 out=`cat $INFOFILE | jgrep --start nodes.*.$i | grep [0-9]`
 metric=`echo $i | sed 's/\./_/g'`
 echo "elasticsearch.$friendlyhost.$metric $out $now"
done

rm $INFOFILE
rm $INFOFILE.time
