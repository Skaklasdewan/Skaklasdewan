#
# Backup and/or Restore fingerprint data
#
# 210626: initial version for OOS 11

sn=fpbr

debug=
b=
bkdir=/sdcard/data
fpfiles="/data/system/users/0/settings_fingerprint.xml /data/vendor_de/0/fpdata"
r=

printHelp () {
cat 1>&2 <<EOF
Usage: $sn [-bdhr]
  Backup and/or restore fingerprint data in
    $fpfiles
  Backups are stored in $bkdir/yymmdd-hhmmss_fpdata.tgz
  
  Note: currently only for OOS 11

 Options:
   -b backs up files
   -d debug mode: only echoes the commands
   -h prints this message
   -r restores a selected backup
   
EOF
}

OPTIND=1 # needed because I run as .
OPTERR=1 # 0|1 print error
while getopts bdhmr xa # 2> /dev/null
do
  case ${xa} in
    b) b=yes ;;
    d) debug=echo ;;
    h) printHelp; exit ;;
    r) r=yes ;;
    *) printHelp; exit ;;
  esac
done
# skip processed args
shift $((OPTIND-1))

# any unexpected arguments?
if [ $# != "0" ]; then
  printHelp; exit
fi

#
# Check backup directory
#
if [ ! -e $bkdir ]; then
  echo "$sn: Cannot find backup directory: $bkdir"
   exit
fi

#
# Backup/restore
#
if [ $b ]; then # backup
  $debug su -c "tar -czf $bkdir/`date +%y%m%d-%H%M%S`_fpdata.tgz $fpfiles"
fi
if [ $r ]; then # restore
  bks=($(ls $bkdir/*fpdata*.tgz))
  # select the backup to be restored
  echo "Available backups:"
  xj=1
  for xc in ${bks[*]}; do
      echo $xj: $(basename $xc)
      let xj+=1
  done
  echo -n "Number of selected backup: "
  read resp rest # read -p won't work from su
  let resp-=1
  if [ "$resp" -ge 0 -a "$resp" -lt ${#bks[*]} ]; then
    echo You chose ${bks[$resp]}
    $debug su -c "tar -xzf ${bks[$resp]} -C /"
    $debug su -c "restorecon $fpfiles"
    echo "$sn: FP restored. Reboot the phone!"
  else
    echo "$sn: Aborting - no backup selected"
    exit
  fi
fi
