# Automate DNSSEC

Scripts to automate DNSSEC management

## Recommendation
### Execute script

```
bash auto_dnssec.sh
# or
chmod +x auto_dnssec.sh
./auto_dnssec.sh
```

If you wish to use `sh`, it is advisable to check that the symbolic link does not point to **dash**.
*Because of the base-10 conversion on the serial, the script cannot be launched with dash*.

To check, run this command.
```
$ readlink -f /bin/sh
/usr/bin/dash
```

## Required

To run the script, you need to define three variables in the script:
* **zone_file**: this file is your zone record. It often takes the form `db.domain.tld`.
* **fichier_dest**: this path must correspond to the location of the `zone_file` file, and will contain the ksk and zsk keys after script execution.
* **domain_zone**: This variable corresponds to the name of the zone for which you wish to define DNSSEC. It takes the form `domain.tld`.

## Options

There are 3 options for DNSSEC management:

* `--ksk` this option must be run every year on the dns server and will create / recreate the zsk and ksk keys, modify the SOA series, sign the zone and restart bind.
```bash
bash auto_dnssec.sh --ksk
```

* `--zsk` this command is run every 3 months and creates the zsk keys, modifies the SOA serial number, signs the zone and restarts bind.
```bash
bash auto_dnssec.sh --zsk
```

* `--sign` this option is used after zone records have been modified. It will sign the registration file and restart bind.
```bash
bash auto_dnssec.sh --sign
```

## Crontab

This script must be run periodically, and can be launched with a crontab.

For example, to recreate zsk keys every 3 months and ksk keys every year.
```bash
crontab -e
0 0 1 */3 * /path/to/script/setup_dnssec.sh --zsk
0 0 * 4 * /path/to/script/setup_dnssec.sh --ksk
```

You can then check that the crontab has been saved with `crontab -l`.

To check the logs you can run the command:
```bash
cat /var/log/syslog | grep "cron"
```
