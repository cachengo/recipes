function get_kubeconfig_path { 
  KUBE_PATH=$(kubectl get pod   -v6 2>&1 |awk  '/Config loaded from file:/{print $NF}')
  echo "$KUBE_PATH"
}