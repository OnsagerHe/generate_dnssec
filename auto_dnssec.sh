#!/usr/bin/env bash

zone_file=''
dest_file=''

domain_zone=''

current_date=$(date +%Y%m%d%H%M%S)
datebit=$(echo $current_date | cut -c 1-8)
timebit=$(echo $current_date | cut -c 9-)
add_one_year=$(date -d "$datebit +1 year" +"%Y%m%d${timebit}")
add_three_month=$(date -d "$datebit +3 month" +"%Y%m%d${timebit}")
add_one_month=$(date -d "$datebit +1 month" +"%Y%m%d${timebit}")

# generate ksk
generate_ksk () {
  dnssec-keygen -f KSK -a RSASHA256 -b 4096 -n ZONE $domain_zone

  # set more comprehensible name
  mv K$domain_zone.+*.key K$domain_zone.ksk.key
  mv K$domain_zone.+*.private K$domain_zone.ksk.private
}

# generate zsk
generate_zsk () {
  dnssec-keygen -a RSASHA256 -b 4096 -n ZONE $domain_zone

  # set more comprehensible name
  mv K$domain_zone.+*.key K$domain_zone.zsk.key
  mv K$domain_zone.+*.private K$domain_zone.zsk.private
}

# signed zone
sign_zone () {
  dnssec-signzone -e$add_one_month -t -g -k K$domain_zone.ksk.key -o $domain_zone db.$domain_zone K$domain_zone.zsk.key
}

update_soa () {
  # Update SOA value
  current_serial=$(awk 'BEGIN{RS="@"} NR==2{print $6}' $zone_file)
  current_serial_date=$(echo $current_serial | cut -c 1-8)

  if [ "$current_serial_date" = "$datebit" ]; then
          current_serial_nbr=$(echo $current_serial | cut -c 9-)
          compute_serial_nbr=$((10#$current_serial_nbr +1))
          new_serial_nbr=$(printf "%02d\n" $compute_serial_nbr)
          new_serial="$current_serial_date$new_serial_nbr"
          echo $new_serial
  else
          new_serial="${datebit}01"
          echo "$new_serial"
  fi

  sed -i -e "s/$current_serial/$new_serial/g" $zone_file
}


# restart bin9
restart_bind () {
  systemctl restart bind9
}

check_file () {
  if [ -z "$zone_file" ] || [ -z "$dest_file" ] || [ -z "$domain_zone" ]
  then
          echo "You should define var dest_file, zone_file and domain_zone."
          exit 1
  else
          if [ -f "$dest_file/$zone_file" ]; then
                  cd $dest_file
          else
                  echo "Path to zone is incorrect: $dest_file/$zone_file"
          fi
  fi
}


if [ "$#" -eq 0 ]; then
  set -- "ksk"
elif [ "$#" -gt 1 ]; then
  echo "Too many arguments."
  exit -1
fi

check_file

case $1 in
  ksk | --ksk)
    echo "Generate ksk key"
    generate_ksk
    generate_zsk
    update_soa
    sign_zone
    restart_bind
    ;;

  zsk | --zsk)
    echo "Generate zsk key"
    generate_zsk
    update_soa
    sign_zone
    restart_bind
    ;;

  sign | --sign)
    echo "Sign zone"
    sign_zone
    restart_bind
    ;;

  *)
    echo "Unknown command"
    ;;
esac
