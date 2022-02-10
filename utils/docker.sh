function create_network {
  docker network inspect "$1" >/dev/null 2>&1 || \
  docker network create --driver bridge "$1"
}

function get_network { 
  NETWORK_NAME=$(docker inspect "$APPID" | jq '.[0].NetworkSettings.Networks' | jq 'keys[0]' | cut -d '"' -f 2)
  echo "$NETWORK_NAME"
}

function delete_network {    
  if [ $( docker network inspect "$1" | grep '"Containers": {},' | wc -l ) -gt 0 ]; then
    docker network rm "$1"
  fi  
}