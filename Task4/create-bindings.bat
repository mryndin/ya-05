@echo off
chcp 65001 >nul
echo === PropDevelopment: Привязка пользователей к ролям ===
echo.

if not exist yaml mkdir yaml

echo [1/4] Привязываем ClusterRole: propdev-viewer...
echo --- > yaml\crb-viewer.yaml
echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\crb-viewer.yaml
echo kind: ClusterRoleBinding >> yaml\crb-viewer.yaml
echo metadata: >> yaml\crb-viewer.yaml
echo   name: propdev-viewers-binding >> yaml\crb-viewer.yaml
echo   labels: >> yaml\crb-viewer.yaml
echo     app: propdevelopment >> yaml\crb-viewer.yaml
echo roleRef: >> yaml\crb-viewer.yaml
echo   apiGroup: rbac.authorization.k8s.io >> yaml\crb-viewer.yaml
echo   kind: ClusterRole >> yaml\crb-viewer.yaml
echo   name: propdev-viewer >> yaml\crb-viewer.yaml
echo subjects: >> yaml\crb-viewer.yaml
echo - kind: ServiceAccount >> yaml\crb-viewer.yaml
echo   name: analyst-bi >> yaml\crb-viewer.yaml
echo   namespace: data-platform >> yaml\crb-viewer.yaml
kubectl apply -f yaml\crb-viewer.yaml
echo   ✓ analyst-bi → propdev-viewer (ClusterRoleBinding)

echo.
echo [2/4] Привязываем ClusterRole: propdev-auditor...
echo --- > yaml\crb-auditor.yaml
echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\crb-auditor.yaml
echo kind: ClusterRoleBinding >> yaml\crb-auditor.yaml
echo metadata: >> yaml\crb-auditor.yaml
echo   name: propdev-auditor-binding >> yaml\crb-auditor.yaml
echo   labels: >> yaml\crb-auditor.yaml
echo     app: propdevelopment >> yaml\crb-auditor.yaml
echo roleRef: >> yaml\crb-auditor.yaml
echo   apiGroup: rbac.authorization.k8s.io >> yaml\crb-auditor.yaml
echo   kind: ClusterRole >> yaml\crb-auditor.yaml
echo   name: propdev-auditor >> yaml\crb-auditor.yaml
echo subjects: >> yaml\crb-auditor.yaml
echo - kind: ServiceAccount >> yaml\crb-auditor.yaml
echo   name: security-auditor >> yaml\crb-auditor.yaml
echo   namespace: kube-system >> yaml\crb-auditor.yaml
kubectl apply -f yaml\crb-auditor.yaml
echo   ✓ security-auditor → propdev-auditor (ClusterRoleBinding)

echo.
echo [3/4] Привязываем ClusterRole: propdev-cluster-admin...
echo --- > yaml\crb-admin.yaml
echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\crb-admin.yaml
echo kind: ClusterRoleBinding >> yaml\crb-admin.yaml
echo metadata: >> yaml\crb-admin.yaml
echo   name: propdev-cluster-admins-binding >> yaml\crb-admin.yaml
echo   labels: >> yaml\crb-admin.yaml
echo     app: propdevelopment >> yaml\crb-admin.yaml
echo roleRef: >> yaml\crb-admin.yaml
echo   apiGroup: rbac.authorization.k8s.io >> yaml\crb-admin.yaml
echo   kind: ClusterRole >> yaml\crb-admin.yaml
echo   name: propdev-cluster-admin >> yaml\crb-admin.yaml
echo subjects: >> yaml\crb-admin.yaml
echo - kind: ServiceAccount >> yaml\crb-admin.yaml
echo   name: default >> yaml\crb-admin.yaml
echo   namespace: kube-system >> yaml\crb-admin.yaml
kubectl apply -f yaml\crb-admin.yaml
echo   ✓ kube-system/default → propdev-cluster-admin (ClusterRoleBinding)

echo.
echo [4/4] Привязываем Role в каждом namespace...

REM Разработчики
for %%d in (sales utility finance) do (
    echo --- > yaml\rb-developer-%%d.yaml
    echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\rb-developer-%%d.yaml
    echo kind: RoleBinding >> yaml\rb-developer-%%d.yaml
    echo metadata: >> yaml\rb-developer-%%d.yaml
    echo   name: propdev-developers-binding >> yaml\rb-developer-%%d.yaml
    echo   namespace: %%d >> yaml\rb-developer-%%d.yaml
    echo   labels: >> yaml\rb-developer-%%d.yaml
    echo     app: propdevelopment >> yaml\rb-developer-%%d.yaml
    echo roleRef: >> yaml\rb-developer-%%d.yaml
    echo   apiGroup: rbac.authorization.k8s.io >> yaml\rb-developer-%%d.yaml
    echo   kind: Role >> yaml\rb-developer-%%d.yaml
    echo   name: propdev-developer >> yaml\rb-developer-%%d.yaml
    echo subjects: >> yaml\rb-developer-%%d.yaml
    echo - kind: ServiceAccount >> yaml\rb-developer-%%d.yaml
    echo   name: dev-%%d >> yaml\rb-developer-%%d.yaml
    echo   namespace: %%d >> yaml\rb-developer-%%d.yaml
    kubectl apply -f yaml\rb-developer-%%d.yaml
    echo   ✓ dev-%%d → propdev-developer (RoleBinding в %%d)
)

REM Team Leads
for %%d in (sales utility finance) do (
    echo --- > yaml\rb-lead-%%d.yaml
    echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\rb-lead-%%d.yaml
    echo kind: RoleBinding >> yaml\rb-lead-%%d.yaml
    echo metadata: >> yaml\rb-lead-%%d.yaml
    echo   name: propdev-lead-binding >> yaml\rb-lead-%%d.yaml
    echo   namespace: %%d >> yaml\rb-lead-%%d.yaml
    echo   labels: >> yaml\rb-lead-%%d.yaml
    echo     app: propdevelopment >> yaml\rb-lead-%%d.yaml
    echo roleRef: >> yaml\rb-lead-%%d.yaml
    echo   apiGroup: rbac.authorization.k8s.io >> yaml\rb-lead-%%d.yaml
    echo   kind: Role >> yaml\rb-lead-%%d.yaml
    echo   name: propdev-namespace-admin >> yaml\rb-lead-%%d.yaml
    echo subjects: >> yaml\rb-lead-%%d.yaml
    echo - kind: ServiceAccount >> yaml\rb-lead-%%d.yaml
    echo   name: lead-%%d >> yaml\rb-lead-%%d.yaml
    echo   namespace: %%d >> yaml\rb-lead-%%d.yaml
    kubectl apply -f yaml\rb-lead-%%d.yaml
    echo   ✓ lead-%%d → propdev-namespace-admin (RoleBinding в %%d)
)

echo.
echo === Готово! ===
echo.
echo Проверка привязок:
echo.
echo ClusterRoleBindings:
kubectl get clusterrolebindings -l app=propdevelopment -o custom-columns="NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[0].name"
echo.
echo RoleBindings по namespace:
kubectl get rolebindings --all-namespaces -l app=propdevelopment -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[0].name"
echo.
echo === Тестирование доступа (примеры) ===
echo.
echo Проверить, что разработчик sales видит поды в sales:
echo   kubectl auth can-i list pods --as=system:serviceaccount:sales:dev-sales -n sales
echo.
echo Проверить, что разработчик sales НЕ видит секреты:
echo   kubectl auth can-i get secrets --as=system:serviceaccount:sales:dev-sales -n sales
echo.
echo Проверить, что аналитик видит поды во всех неймспейсах:
echo   kubectl auth can-i list pods --as=system:serviceaccount:data-platform:analyst-bi --all-namespaces
echo.
pause