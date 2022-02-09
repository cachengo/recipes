function update_status {
  cachengo-cli updateInstallStatus $APPID $1
}

function declare_secret {
  cachengo-cli declareSecret -i $APPID -n $1 -v $2
}
