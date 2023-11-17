Work in progress...


Prometheus default login
Username: admin
Password: prom-operator

Import Dashboard ID: 1860

kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

kubectl port-forward svc/vproapp-service 8083:80


kubectl port-forward svc/argocd-server -n argocd 8082:80
Ref: https://argo-cd.readthedocs.io/en/stable/getting_started/


https://localhost:8080
