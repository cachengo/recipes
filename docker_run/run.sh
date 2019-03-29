source "utils/cachengo.sh"
source "utils/parameters.sh"

function install {
  update_status "Installing"
  local PORTS_ARR
  local ENVVARS_ARR
  array_from_json_list PORTS_ARR "$PORTS"
  array_from_json_list ENVVARS_ARR "$ENVVARS"
  declare -p PORTS_ARR
  docker run "${PORTS_ARR[@]/#/-p}" "${ENVVARS_ARR[@]/#/-e}" -n $APPID $IMAGE
  update_status "Installed"
}

function uninstall {
  update_status "Uninstalling"
  docker stop $APPID
  docker rm $APPID
  update_status "Uninstalled"
}

while getopts 'iu' flag; do
  case "${flag}" in
    i) install ;;
    u) uinstall ;;
  esac
done
