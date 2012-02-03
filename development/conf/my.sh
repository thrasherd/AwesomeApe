#!/bin/bash

# Calculating parameters for my.cnf
# Based on the (mt) Wiki
# http://wiki.mediatemple.net/w/%28dv%29_4.0_-_Making_It_Better_::_General_MySQL_Tuning

ramCount=`awk 'match($0,/vmguar/) {print $4}' /proc/user_beancounters`
ramBase=-16 && for ((;ramCount>1;ramBase++)); do ramCount=$((ramCount/2)); done

cat <<EOF > /etc/my.cnf
[mysqld]
# Basic settings
user = mysql
datadir = /var/lib/mysql
socket = /var/lib/mysql/mysql.sock

# Security settings
local-infile = 0
symbolic-links = 0

# Memory and cache settings
query_cache_type = 1
query_cache_size = $((2**($ramBase+2)))M
thread_cache_size = $((2**($ramBase+2)))
table_cache = $((2**($ramBase+7)))
tmp_table_size = $((2**($ramBase+3)))M
max_heap_table_size = $((2**($ramBase+3)))M
join_buffer_size = ${ramBase}M
key_buffer_size = $((2**($ramBase+4)))M
max_connections = $((100 + (($ramBase-1) * 50)))
wait_timeout = 300

# Innodb settings
innodb_buffer_pool_size = $((2**($ramBase+3)))M
innodb_additional_mem_pool_size = ${ramBase}M
innodb_log_buffer_size = ${ramBase}M
innodb_thread_concurrency = $((2**$ramBase))

[mysqld_safe]
# Basic safe settings
log-error = /var/log/mysqld.log
pid-file = /var/run/mysqld/mysqld.pid
EOF
