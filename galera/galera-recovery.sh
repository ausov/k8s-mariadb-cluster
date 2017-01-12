#! /bin/bash

user=mysql

log() {
	local msg="galera-recovery.sh: $@"
	# Print all messages to stderr as we reserve stdout for printing
	# --wsrep-start-position=XXXX.
	echo "$msg" >&2
}

#log "Checking whether recovery required..."
POSITION=''

if ! [ -f /var/lib/mysql/ibdata1 ]; then
	log "No ibdata1 found, starting a fresh node..."
	exit 0

elif ! [ -f /var/lib/mysql/grastate.dat ]; then
	log "Missing grastate.dat file..."

elif ! grep -q 'seqno:' /var/lib/mysql/grastate.dat; then
	log "Invalid grastate.dat file..."

elif grep -q '00000000-0000-0000-0000-000000000000' /var/lib/mysql/grastate.dat; then
	log "uuid is not known..."

else
	uuid=$(awk '/^uuid:/{print $2}' /var/lib/mysql/grastate.dat)
	seqno=$(awk '/^seqno:/{print $2}' /var/lib/mysql/grastate.dat)
	if [ "$seqno" = "-1" ]; then
		log "uuid is known but seqno is not..."
	elif [ -n "$uuid" ] && [ -n "$seqno" ]; then
		POSITION="$uuid:$seqno"
		log "Recovered position from grastate.dat: $POSITION"
	else
		log "The grastate.dat file appears to be corrupt:"
		log "##########################"
		log "'`cat /var/lib/mysql/grastate.dat`'"
		log "##########################"
	fi
fi

if [ -z $POSITION ]; then
	log "Attempting to recover GTID positon..."
	tmpfile=$(mktemp -t wsrep_recover.XXXXXX)
	eval mysqld --user=$user --wsrep-on=ON \
			--wsrep_sst_method=skip \
			--wsrep_cluster_address=gcomm:// \
			--skip-networking \
			--wsrep-recover \
			--log-error="$tmpfile"
	if [ $? -ne 0 ]; then
		# Something went wrong, let us also print the error log so that it
		# shows up in systemctl status output as a hint to the user.
		log "Failed to start mysqld for wsrep recovery: '`cat $tmpfile`'"
		exit 1
	fi
	POSITION=$(sed -n 's/.*WSREP: Recovered position:\s*//p' $tmpfile)
	rm -f $tmpfile
fi

if [ -z $POSITION ]; then
	log "=================================================="
	log "[FATAL] Could not determine WSREP position. Aborting!"
	log "=================================================="
	exit 1
else
	log "Found WSREP position: $POSITION"
	sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/g' /var/lib/mysql/grastate.dat
	echo "--wsrep_start_position=$POSITION"
fi
