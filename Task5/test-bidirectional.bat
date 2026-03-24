@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
echo === PropDevelopment: Тестирование двустороннего трафика ===
echo.

REM === Проверка подов ===
echo [1/4] Проверяем поды...
kubectl get pods -n propdev-netpol --no-headers | findstr Running >nul
if %ERRORLEVEL% NEQ 0 (
    echo ОШИБКА: Поды не запущены
    kubectl get pods -n propdev-netpol
    pause
    exit /b 1
)
echo   ✓ Поды запущены
echo.

REM === Тесты двустороннего трафика ===
echo [2/4] Тесты РАЗРЕШЁННОГО трафика (должны быть успешными):
echo ---------------------------------------------------------

echo.
echo Тест 1: front-end -^> back-end-api
kubectl exec -n propdev-netpol front-end-app -- curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://back-end-api-app | findstr "200" >nul
if !ERRORLEVEL! EQU 0 (
    echo   [✓ PASS] front-end -^> back-end-api
) else (
    echo   [✗ FAIL] front-end -^> back-end-api
)

echo.
echo Тест 2: back-end-api -^> front-end
kubectl exec -n propdev-netpol back-end-api-app -- curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://front-end-app | findstr "200" >nul
if !ERRORLEVEL! EQU 0 (
    echo   [✓ PASS] back-end-api -^> front-end
) else (
    echo   [✗ FAIL] back-end-api -^> front-end
)

echo.
echo Тест 3: admin-front-end -^> admin-back-end-api
kubectl exec -n propdev-netpol admin-front-end-app -- curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://admin-back-end-api-app | findstr "200" >nul
if !ERRORLEVEL! EQU 0 (
    echo   [✓ PASS] admin-front-end -^> admin-back-end-api
) else (
    echo   [✗ FAIL] admin-front-end -^> admin-back-end-api
)

echo.
echo Тест 4: admin-back-end-api -^> admin-front-end
kubectl exec -n propdev-netpol admin-back-end-api-app -- curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://admin-front-end-app | findstr "200" >nul
if !ERRORLEVEL! EQU 0 (
    echo   [✓ PASS] admin-back-end-api -^> admin-front-end
) else (
    echo   [✗ FAIL] admin-back-end-api -^> admin-front-end
)

REM === Тесты заблокированного трафика ===
echo.
echo [3/4] Тесты ЗАБЛОКИРОВАННОГО трафика (должны быть отклонены):
echo -------------------------------------------------------------

echo.
echo Тест 5: front-end -^> admin-back-end-api
kubectl exec -n propdev-netpol front-end-app -- curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://admin-back-end-api-app | findstr "200" >nul
if !ERRORLEVEL! NEQ 0 (
    echo   [✓ PASS] front-end -^> admin-back-end-api - ЗАБЛОКИРОВАНО
) else (
    echo   [✗ FAIL] front-end -^> admin-back-end-api - РАЗРЕШЕНО (ошибка!)
)

echo.
echo Тест 6: admin-front-end -^> back-end-api
kubectl exec -n propdev-netpol admin-front-end-app -- curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://back-end-api-app | findstr "200" >nul
if !ERRORLEVEL! NEQ 0 (
    echo   [✓ PASS] admin-front-end -^> back-end-api - ЗАБЛОКИРОВАНО
) else (
    echo   [✗ FAIL] admin-front-end -^> back-end-api - РАЗРЕШЕНО (ошибка!)
)

echo.
echo [4/4] МАТРИЦА РЕЗУЛЬТАТОВ:
echo ====================================================================
echo Источник              ^| Назначение                ^| Ожидаемый результат
echo ====================================================================
echo front-end             ^| back-end-api              ^| Разрешено
echo back-end-api          ^| front-end                 ^| Разрешено
echo admin-front-end       ^| admin-back-end-api        ^| Разрешено
echo admin-back-end-api    ^| admin-front-end           ^| Разрешено
echo front-end             ^| admin-back-end-api        ^| Заблокировано
echo admin-front-end       ^| back-end-api              ^| Заблокировано
echo ====================================================================

echo.
echo ВНИМАНИЕ: В обратном направлении (back-end-api -^> front-end) 
echo трафик разрешён, что соответствует условию задачи.
echo.

pause