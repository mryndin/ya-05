@echo off
setlocal enabledelayedexpansion

echo [1/6] Cleaning up...
minikube delete

echo [2/6] Initializing Minikube node...
:: Запускаем без параметров, чтобы создать машину
minikube start --driver=docker --memory=4096 --cpus=2

:: Ждем, пока нода будет готова принять файлы
timeout /t 10 > nul

echo [3/6] Copying audit policy to a guaranteed mount path...
:: /etc/ssl/certs/ всегда виден внутри контейнера apiserver
minikube cp audit-policy.yaml /etc/ssl/certs/audit-policy.yaml

echo [4/6] Restarting with Audit Policy...
:: Используем пути, которые apiserver точно увидит
minikube start ^
  --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml ^
  --extra-config=apiserver.audit-log-path=/var/log/audit.log

if %errorlevel% neq 0 (
    echo.
    echo [CRITICAL ERROR] API Server failed to start again.
    echo Printing last 20 lines of apiserver logs:
    minikube ssh "docker logs $(docker ps -q --filter name=kube-apiserver) | tail -n 20"
    exit /b %errorlevel%
)

echo [5/6] System is UP. Running simulation...
:: Даем API-серверу время "продышаться"
timeout /t 20 > nul

:: Проверка: видит ли kubectl систему
kubectl get nodes

:: Создаем ресурсы для инцидента
kubectl create ns secure-ops
kubectl create sa monitoring -n secure-ops
kubectl run attacker-pod --image=alpine -n secure-ops -- sleep 3600

:: Имитация действий
kubectl get secrets --as=system:serviceaccount:secure-ops:monitoring -n secure-ops > nul 2>&1

:: Создание привилегированного пода
(
echo apiVersion: v1
echo kind: Pod
echo metadata:
echo   name: privileged-pod
echo   namespace: secure-ops
echo spec:
echo   containers:
echo   - name: pwn
echo     image: alpine
echo     command: ["sleep", "3600"]
echo     securityContext:
echo       privileged: true
echo   restartPolicy: Never
) > priv.yaml
kubectl apply -f priv.yaml
del priv.yaml

echo [6/6] Extracting logs...
:: Важно: даем логам записаться
timeout /t 10 > nul
minikube ssh "sudo cat /var/log/audit.log" > audit.log

if exist filter_audit.py (
    python filter_audit.py
)

echo Done. Check audit-extract.json.
pause