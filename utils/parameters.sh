

function array_from_json_list {
  local -n arr=$1
  readarray -td '' arr < <(awk '{ gsub(/, /,"\0"); print; }' <<<"$2, ")
  unset 'arr[-1]'
  arr=( "${arr[@]##[}" )
  arr=( "${arr[@]##\"}" )
  arr=( "${arr[@]%]}" )
  arr=( "${arr[@]%\"}" )
}
