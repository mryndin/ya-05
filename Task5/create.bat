@echo off
chcp 65001 >nul
echo === PropDevelopment: Task 5 — Полная переустановка ===
echo.

REM [1] Останавливаем и удаляем старый Minikube
echo [1/5] Очищаем старый Minikube...
minikube delete
timeout /t 3 /nobreak >nul

REM [2] Запускаем новый Minikube с Calico
echo [2/5] Запускаем Minikube с Calico...
minikube start --cni=calico --memory=4096 --cpus=2
timeout /t 10 /nobreak >nul


REM [3] Проверяем Calico и DNS
echo [3/5] Проверяем Calico и DNS...
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=60s 2>nul
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=60s 2>nul
kubectl get pods -n kube-system | findstr "calico coredns"
timeout /t 5 /nobreak >nul

REM [4] Разворачиваем сервисы и политики
echo.
echo [4/5] Разворачиваем сервисы и политики...
call deploy-services.bat

REM [5] Тестируем трафик
echo.
echo [5/5] Тестируем трафик...
call test-bidirectional.bat

echo.
echo === Готово! ===
pause