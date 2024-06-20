function wait_for_service_active {
  x=0
  while [ "$( systemctl is-active $1)" != "active" ]
  do
    if [ $x -ge $2 ]; then
      echo "Error starting service...Exiting"
      exit 1
    fi
    sleep 5
    x=$(( $x + 1 ))
  done
}