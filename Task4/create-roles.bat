@echo off
chcp 65001 >nul
echo === PropDevelopment: Создание ролей Kubernetes ===
echo.

if not exist yaml mkdir yaml

echo [1/5] Создаём ClusterRole: propdev-viewer (read-only для всех)...
echo --- > yaml\clusterrole-viewer.yaml
echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\clusterrole-viewer.yaml
echo kind: ClusterRole >> yaml\clusterrole-viewer.yaml
echo metadata: >> yaml\clusterrole-viewer.yaml
echo   name: propdev-viewer >> yaml\clusterrole-viewer.yaml
echo   labels: >> yaml\clusterrole-viewer.yaml
echo     app: propdevelopment >> yaml\clusterrole-viewer.yaml
echo rules: >> yaml\clusterrole-viewer.yaml
echo - apiGroups: [""] >> yaml\clusterrole-viewer.yaml
echo   resources: ["pods", "services", "configmaps", "events", "namespaces"] >> yaml\clusterrole-viewer.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-viewer.yaml
echo - apiGroups: ["apps"] >> yaml\clusterrole-viewer.yaml
echo   resources: ["deployments", "replicasets", "statefulsets"] >> yaml\clusterrole-viewer.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-viewer.yaml
echo - apiGroups: ["batch"] >> yaml\clusterrole-viewer.yaml
echo   resources: ["jobs", "cronjobs"] >> yaml\clusterrole-viewer.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-viewer.yaml
echo - apiGroups: [""] >> yaml\clusterrole-viewer.yaml
echo   resources: ["pods/log"] >> yaml\clusterrole-viewer.yaml
echo   verbs: ["get", "list"] >> yaml\clusterrole-viewer.yaml
kubectl apply -f yaml\clusterrole-viewer.yaml
echo   ✓ ClusterRole 'propdev-viewer' создана

echo.
echo [2/5] Создаём ClusterRole: propdev-auditor (чтение секретов для ИБ)...
echo --- > yaml\clusterrole-auditor.yaml
echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\clusterrole-auditor.yaml
echo kind: ClusterRole >> yaml\clusterrole-auditor.yaml
echo metadata: >> yaml\clusterrole-auditor.yaml
echo   name: propdev-auditor >> yaml\clusterrole-auditor.yaml
echo   labels: >> yaml\clusterrole-auditor.yaml
echo     app: propdevelopment >> yaml\clusterrole-auditor.yaml
echo rules: >> yaml\clusterrole-auditor.yaml
echo - apiGroups: [""] >> yaml\clusterrole-auditor.yaml
echo   resources: ["pods", "services", "configmaps", "events", "namespaces"] >> yaml\clusterrole-auditor.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-auditor.yaml
echo - apiGroups: ["apps"] >> yaml\clusterrole-auditor.yaml
echo   resources: ["deployments", "replicasets", "statefulsets"] >> yaml\clusterrole-auditor.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-auditor.yaml
echo - apiGroups: [""] >> yaml\clusterrole-auditor.yaml
echo   resources: ["secrets"] >> yaml\clusterrole-auditor.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-auditor.yaml
echo - apiGroups: ["audit.k8s.io"] >> yaml\clusterrole-auditor.yaml
echo   resources: ["events"] >> yaml\clusterrole-auditor.yaml
echo   verbs: ["get", "list", "watch"] >> yaml\clusterrole-auditor.yaml
kubectl apply -f yaml\clusterrole-auditor.yaml
echo   ✓ ClusterRole 'propdev-auditor' создана

echo.
echo [3/5] Создаём Role: propdev-developer (для разработчиков в своём namespace)...
for %%n in (sales utility finance data-platform) do (
    echo --- > yaml\role-developer-%%n.yaml
    echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\role-developer-%%n.yaml
    echo kind: Role >> yaml\role-developer-%%n.yaml
    echo metadata: >> yaml\role-developer-%%n.yaml
    echo   name: propdev-developer >> yaml\role-developer-%%n.yaml
    echo   namespace: %%n >> yaml\role-developer-%%n.yaml
    echo   labels: >> yaml\role-developer-%%n.yaml
    echo     app: propdevelopment >> yaml\role-developer-%%n.yaml
    echo rules: >> yaml\role-developer-%%n.yaml
    echo - apiGroups: [""] >> yaml\role-developer-%%n.yaml
    echo   resources: ["pods", "pods/log", "pods/exec"] >> yaml\role-developer-%%n.yaml
    echo   verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] >> yaml\role-developer-%%n.yaml
    echo - apiGroups: ["apps"] >> yaml\role-developer-%%n.yaml
    echo   resources: ["deployments", "replicasets"] >> yaml\role-developer-%%n.yaml
    echo   verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] >> yaml\role-developer-%%n.yaml
    echo - apiGroups: [""] >> yaml\role-developer-%%n.yaml
    echo   resources: ["services", "configmaps"] >> yaml\role-developer-%%n.yaml
    echo   verbs: ["get", "list", "watch", "create", "update", "patch", "delete"] >> yaml\role-developer-%%n.yaml
    kubectl apply -f yaml\role-developer-%%n.yaml
    echo   ✓ Role 'propdev-developer' создана в namespace '%%n'
)
echo.

echo [4/5] Создаём Role: propdev-namespace-admin (для Team Lead)...

for %%n in (sales utility finance) do (
    echo --- > yaml\role-admin-%%n.yaml
    echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\role-admin-%%n.yaml
    echo kind: Role >> yaml\role-admin-%%n.yaml
    echo metadata: >> yaml\role-admin-%%n.yaml
    echo   name: propdev-namespace-admin >> yaml\role-admin-%%n.yaml
    echo   namespace: %%n >> yaml\role-admin-%%n.yaml
    echo   labels: >> yaml\role-admin-%%n.yaml
    echo     app: propdevelopment >> yaml\role-admin-%%n.yaml
    echo rules: >> yaml\role-admin-%%n.yaml
    echo - apiGroups: ["*"] >> yaml\role-admin-%%n.yaml
    echo   resources: ["*"] >> yaml\role-admin-%%n.yaml
    echo   verbs: ["*"] >> yaml\role-admin-%%n.yaml
    echo - apiGroups: ["rbac.authorization.k8s.io"] >> yaml\role-admin-%%n.yaml
    echo   resources: ["roles", "rolebindings"] >> yaml\role-admin-%%n.yaml
    echo   verbs: ["get", "list", "watch"] >> yaml\role-admin-%%n.yaml
    echo - apiGroups: [""] >> yaml\role-admin-%%n.yaml
    echo   resources: ["secrets"] >> yaml\role-admin-%%n.yaml
    echo   verbs: ["get", "list", "watch"] >> yaml\role-admin-%%n.yaml
    kubectl apply -f yaml\role-admin-%%n.yaml
    echo   ✓ Role 'propdev-namespace-admin' создана в namespace '%%n'
)

echo.
echo [5/5] Создаём ClusterRole: propdev-cluster-admin (для DevOps и ИБ)...
echo --- > yaml\clusterrole-admin.yaml
echo apiVersion: rbac.authorization.k8s.io/v1 >> yaml\clusterrole-admin.yaml
echo kind: ClusterRole >> yaml\clusterrole-admin.yaml
echo metadata: >> yaml\clusterrole-admin.yaml
echo   name: propdev-cluster-admin >> yaml\clusterrole-admin.yaml
echo   labels: >> yaml\clusterrole-admin.yaml
echo     app: propdevelopment >> yaml\clusterrole-admin.yaml
echo rules: >> yaml\clusterrole-admin.yaml
echo - apiGroups: ["*"] >> yaml\clusterrole-admin.yaml
echo   resources: ["*"] >> yaml\clusterrole-admin.yaml
echo   verbs: ["*"] >> yaml\clusterrole-admin.yaml
kubectl apply -f yaml\clusterrole-admin.yaml
echo   ✓ ClusterRole 'propdev-cluster-admin' создана

echo.
echo === Готово! ===
echo.
echo Созданные роли:
kubectl get clusterroles -l app=propdevelopment -o name
kubectl get roles --all-namespaces -l app=propdevelopment -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name"
echo.
pause