@echo off
chcp 65001 >nul

REM 1. Create namespace
echo Creating namespace...
kubectl delete namespace propdev-netpol 2>nul
kubectl create namespace propdev-netpol

REM 2. Deploy services with labels
echo Deploying services...
kubectl run front-end-app --image=nginx --labels role=front-end --expose --port=80 -n propdev-netpol
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port=80 -n propdev-netpol
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port=80 -n propdev-netpol
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port=80 -n propdev-netpol

REM 3. Wait for pods to be ready
echo Waiting for pods to be ready...
timeout /t 30 /nobreak >nul

REM 4. Show pods and services
echo.
echo === Pods with labels ===
kubectl get pods -n propdev-netpol --show-labels
echo.
echo === Services ===
kubectl get services -n propdev-netpol

REM 5. Apply network policies
echo.
echo Applying network policies...
kubectl apply -f non-admin-api-allow.yaml

echo.
echo === Network Policies ===
kubectl get networkpolicies -n propdev-netpol

echo.
echo Waiting for policies to take effect...
timeout /t 30 /nobreak >nul