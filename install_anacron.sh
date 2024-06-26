mkdir -p $HOME/.anacron/{spool, cron.daily, cron.weekly, cron.monthly}

cat <<EOF > $HOME/.anacron/anacrontab 
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# These replace cron's entries
1 5 daily-cron nice run-parts --report ${HOME}/.anacron/cron.daily
7 10 weekly-cron nice run-parts --report ${HOME}/.anacron/cron.weekly
@monthly 15 monthly-cron nice run-parts --report ${HOME}/.anacron/cron.monthly
EOF

echo @hourly /usr/sbin/anacron -s -t $HOME/.anacron/anacrontab -S $HOME/.anacron/spool | crontab -e 

