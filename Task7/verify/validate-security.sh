#!/bin/bash

NAMESPACE="audit-zone"
POD_NAME="pod-root-fixed"

echo "--- Checking Pod Security Settings ---"

# 1. Проверка UID (должен быть 1000)
USER_ID=$(kubectl exec -n $NAMESPACE $POD_NAME -- id -u)
if [ "$USER_ID" == "1000" ]; then
    echo "✅ [PASS] User is non-root (UID: $USER_ID)"
else
    echo "❌ [FAIL] User is root or not 1000 (UID: $USER_ID)"
fi

# 2. Проверка AllowPrivilegeEscalation
PRIV_ESC=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')
if [ "$PRIV_ESC" == "false" ]; then
    echo "✅ [PASS] AllowPrivilegeEscalation is false"
else
    echo "❌ [FAIL] AllowPrivilegeEscalation is true or not set"
fi

# 3. Проверка ReadOnlyRootFilesystem
READ_ONLY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')
if [ "$READ_ONLY" == "true" ]; then
    echo "✅ [PASS] ReadOnlyRootFilesystem is true"
else
    echo "❌ [FAIL] ReadOnlyRootFilesystem is not true"
fi

# 4. Боевой тест на запись в корень
echo "--- Testing write access to / ---"
kubectl exec -it $POD_NAME -n $NAMESPACE -- touch /test_file.txt 2>/dev/null
if [ $? -ne 0 ]; then
    echo "✅ [PASS] Root filesystem is indeed read-only"
else
    echo "❌ [FAIL] Root filesystem is writable!"
fi