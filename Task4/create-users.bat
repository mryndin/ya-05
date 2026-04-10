@echo off
chcp 65001 >nul
echo === PropDevelopment: Создание пользователей в Kubernetes ===
echo.

REM Создаём директорию для YAML-файлов
if not exist yaml mkdir yaml

echo [1/4] Создаём namespaces для доменов...
echo ---
echo apiVersion: v1 > yaml\namespaces.yaml
echo kind: NamespaceList >> yaml\namespaces.yaml
echo items: >> yaml\namespaces.yaml
echo - metadata: >> yaml\namespaces.yaml
echo     name: sales >> yaml\namespaces.yaml
echo     labels: >> yaml\namespaces.yaml
echo       domain: sales >> yaml\namespaces.yaml
echo - metadata: >> yaml\namespaces.yaml
echo     name: utility >> yaml\namespaces.yaml
echo     labels: >> yaml\namespaces.yaml
echo       domain: utility >> yaml\namespaces.yaml
echo - metadata: >> yaml\namespaces.yaml
echo     name: finance >> yaml\namespaces.yaml
echo     labels: >> yaml\namespaces.yaml
echo       domain: finance >> yaml\namespaces.yaml
echo - metadata: >> yaml\namespaces.yaml
echo     name: data-platform >> yaml\namespaces.yaml
echo     labels: >> yaml\namespaces.yaml
echo       domain: data >> yaml\namespaces.yaml
kubectl apply -f yaml\namespaces.yaml
echo   ✓ Namespaces созданы

echo.
echo [2/4] Создаём сервис-аккаунты разработчиков...

REM dev-sales
echo --- > yaml\sa-dev-sales.yaml
echo apiVersion: v1 >> yaml\sa-dev-sales.yaml
echo kind: ServiceAccount >> yaml\sa-dev-sales.yaml
echo metadata: >> yaml\sa-dev-sales.yaml
echo   name: dev-sales >> yaml\sa-dev-sales.yaml
echo   namespace: sales >> yaml\sa-dev-sales.yaml
echo   labels: >> yaml\sa-dev-sales.yaml
echo     role: developer >> yaml\sa-dev-sales.yaml
kubectl apply -f yaml\sa-dev-sales.yaml

REM dev-utility
echo --- > yaml\sa-dev-utility.yaml
echo apiVersion: v1 >> yaml\sa-dev-utility.yaml
echo kind: ServiceAccount >> yaml\sa-dev-utility.yaml
echo metadata: >> yaml\sa-dev-utility.yaml
echo   name: dev-utility >> yaml\sa-dev-utility.yaml
echo   namespace: utility >> yaml\sa-dev-utility.yaml
echo   labels: >> yaml\sa-dev-utility.yaml
echo     role: developer >> yaml\sa-dev-utility.yaml
kubectl apply -f yaml\sa-dev-utility.yaml

REM dev-finance
echo --- > yaml\sa-dev-finance.yaml
echo apiVersion: v1 >> yaml\sa-dev-finance.yaml
echo kind: ServiceAccount >> yaml\sa-dev-finance.yaml
echo metadata: >> yaml\sa-dev-finance.yaml
echo   name: dev-finance >> yaml\sa-dev-finance.yaml
echo   namespace: finance >> yaml\sa-dev-finance.yaml
echo   labels: >> yaml\sa-dev-finance.yaml
echo     role: developer >> yaml\sa-dev-finance.yaml
kubectl apply -f yaml\sa-dev-finance.yaml
echo   ✓ Сервис-аккаунты разработчиков созданы

echo.
echo [3/4] Создаём сервис-аккаунты аналитиков и администраторов...

REM analyst-bi
echo --- > yaml\sa-analyst-bi.yaml
echo apiVersion: v1 >> yaml\sa-analyst-bi.yaml
echo kind: ServiceAccount >> yaml\sa-analyst-bi.yaml
echo metadata: >> yaml\sa-analyst-bi.yaml
echo   name: analyst-bi >> yaml\sa-analyst-bi.yaml
echo   namespace: data-platform >> yaml\sa-analyst-bi.yaml
echo   labels: >> yaml\sa-analyst-bi.yaml
echo     role: viewer >> yaml\sa-analyst-bi.yaml
kubectl apply -f yaml\sa-analyst-bi.yaml

REM lead-sales
echo --- > yaml\sa-lead-sales.yaml
echo apiVersion: v1 >> yaml\sa-lead-sales.yaml
echo kind: ServiceAccount >> yaml\sa-lead-sales.yaml
echo metadata: >> yaml\sa-lead-sales.yaml
echo   name: lead-sales >> yaml\sa-lead-sales.yaml
echo   namespace: sales >> yaml\sa-lead-sales.yaml
echo   labels: >> yaml\sa-lead-sales.yaml
echo     role: namespace-admin >> yaml\sa-lead-sales.yaml
kubectl apply -f yaml\sa-lead-sales.yaml

REM security-auditor
echo --- > yaml\sa-security-auditor.yaml
echo apiVersion: v1 >> yaml\sa-security-auditor.yaml
echo kind: ServiceAccount >> yaml\sa-security-auditor.yaml
echo metadata: >> yaml\sa-security-auditor.yaml
echo   name: security-auditor >> yaml\sa-security-auditor.yaml
echo   namespace: kube-system >> yaml\sa-security-auditor.yaml
echo   labels: >> yaml\sa-security-auditor.yaml
echo     role: auditor >> yaml\sa-security-auditor.yaml
kubectl apply -f yaml\sa-security-auditor.yaml
echo   ✓ Сервис-аккаунты аналитиков созданы

echo.
echo [4/4] Генерируем токены доступа...
for %%s in (dev-sales dev-utility dev-finance analyst-bi lead-sales security-auditor) do (
    echo   ✓ Сервис-аккаунт '%%s' готов к использованию
)

echo.
echo === Готово! ===
echo.
echo Доступные сервис-аккаунты:
kubectl get sa --all-namespaces -l role -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,ROLE:.metadata.labels.role"
echo.
echo Для получения токена используйте:
echo   kubectl create token ^<serviceaccount^> -n ^<namespace^>
echo.
echo Пример:
echo   kubectl create token dev-sales -n sales
echo.
pause