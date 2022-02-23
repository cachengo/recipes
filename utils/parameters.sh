

function array_from_json_list {
  local -n arr=$1
  echo $2
  while IFS= read -r -d '' item; do
    arr+=( "$item" )
  done < <(jq -j '.[] | ((. | sub("\u0000"; "<NUL>")) + "\u0000")' <<<"$2")
}
