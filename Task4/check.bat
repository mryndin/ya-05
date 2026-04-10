REM 5. Проверьте результат
kubectl get sa --all-namespaces -l role
kubectl get clusterroles -l app=propdevelopment
kubectl get roles --all-namespaces -l app=propdevelopment

REM 6. Тест авторизации
kubectl auth can-i list pods --as=system:serviceaccount:sales:dev-sales -n sales
kubectl auth can-i get secrets --as=system:serviceaccount:sales:dev-sales -n sales