#!/usr/bin/bash

screen -L -Logfile /var/www/html/reports/screen_output_$(date +'%Y-%m-%d').log -d -m bash scripts/run_all.sh.sh
