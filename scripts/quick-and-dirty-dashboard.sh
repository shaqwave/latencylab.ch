watch -n2 '
  echo -e "\n📦 Pods:" && kubectl get pods -n latencylab-is
  echo -e "\n🔌 Services:" && kubectl get svc -n latencylab-is
  echo -e "\n🚀 Deployments:" && kubectl get deploy -n latencylab-is
  echo -e "\n🌐 Ingress:" && kubectl get ingress -n latencylab-is
  echo -e "\n📦 PVCs:" && kubectl get pvc -n latencylab-is
'
