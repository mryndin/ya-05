Task 5: Управление трафиком внутри кластера Kubernetes
======================================================

PropDevelopment — Сетевые политики для изоляции микросервисов

**Статус:** ✅ Выполнено **Дата:** 2026 **Среда:** Minikube + Calico (Windows CMD)

📋 Содержание
-------------

*   [1\. Описание задачи](#description)
*   [2\. Требования](#requirements)
*   [3\. Структура проекта](#structure)
*   [4\. Быстрый старт](#quickstart)
*   [5\. Пошаговая установка](#installation)
*   [6\. Сетевые политики](#policies)
*   [7\. Тестирование](#testing)
*   [8\. Матрица трафика](#matrix)
*   [9\. Отладка](#debug)
*   [10\. Результаты](#results)

📝 1. Описание задачи
---------------------

Реализовать управление сетевым трафиком между микросервисами PropDevelopment с помощью **NetworkPolicy** в Kubernetes:

*   ✅ Разрешить трафик между `front-end` ↔ `back-end-api`
*   ✅ Разрешить трафик между `admin-front-end` ↔ `admin-back-end-api`
*   ❌ Заблокировать весь остальной межсервисный трафик
*   🔒 Изолировать admin и non-admin сервисы друг от друга

🔧 2. Требования
----------------

*   **Minikube** v1.38.1+ (с поддержкой Calico)
*   **Kubernetes** v1.35.0+
*   **Docker** 29.2.0+
*   **Windows 10/11** (PowerShell или CMD)
*   **kubectl** (устанавливается с Minikube)

📁 3. Структура проекта
-----------------------

Task5/  
├── create.bat # Полная переустановка (Minikube + сервисы)  
├── deploy-services.bat # Развёртывание сервисов и политик  
├── test-bidirectional.bat # Тестирование сетевого трафика  
├── non-admin-api-allow.yaml # Сетевые политики (основной файл)  
└── README.md # Документация  

🚀 4. Быстрый старт
-------------------

⚠️ **Внимание:** Эта команда удалит текущий кластер Minikube и создаст новый!

    create.bat

Этот скрипт автоматически:

1.  Удаляет старый Minikube
2.  Создаёт новый кластер с Calico
3.  Разворачивает сервисы
4.  Применяет политики
5.  Запускает тесты

📖 5. Пошаговая установка
-------------------------

### Шаг 1: Подготовка Minikube с Calico

    REM Удалить старый кластер
    minikube delete
    
    REM Создать новый с Calico
    minikube start --cni=calico --memory=4096 --cpus=2
    
    REM Проверить Calico
    kubectl get pods -n kube-system -l k8s-app=calico-node

**Ожидаемый вывод:**

    NAME                READY   STATUS    RESTARTS   AGE
    calico-node-xxxxx   1/1     Running   0          2m

### Шаг 2: Развёртывание сервисов

    REM Или автоматически:
    call deploy-services.bat
    
    REM Или вручную:
    kubectl create namespace propdev-netpol
    
    kubectl run front-end-app --image=nginx --labels role=front-end --expose --port=80 -n propdev-netpol
    kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port=80 -n propdev-netpol
    kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port=80 -n propdev-netpol
    kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port=80 -n propdev-netpol
    
    REM Проверка
    kubectl get pods -n propdev-netpol --show-labels
    kubectl get services -n propdev-netpol

### Шаг 3: Применение сетевых политик

    kubectl apply -f non-admin-api-allow.yaml
    
    REM Проверка
    kubectl get networkpolicies -n propdev-netpol

🔐 6. Сетевые политики
----------------------

### Принцип работы

NetworkPolicy работают по принципу **"запрещено всё, что явно не разрешено"**.

Мы создали **4 политики** для обеспечения **двусторонней связи** между парами сервисов:

### Политика 1: `allow-front-to-backend`

*   **Цель:** `back-end-api`
*   **Разрешает:** Входящий трафик от `front-end` на порт 80 + Исходящий к `front-end`

### Политика 2: `allow-front-to-backend-egress`

*   **Цель:** `front-end`
*   **Разрешает:** Исходящий трафик к `back-end-api` + DNS (порт 53)

### Политика 3: `allow-admin-front-to-admin-backend`

*   **Цель:** `admin-back-end-api`
*   **Разрешает:** Входящий трафик от `admin-front-end` на порт 80 + Исходящий к `admin-front-end`

### Политика 4: `allow-admin-front-to-admin-backend-egress`

*   **Цель:** `admin-front-end`
*   **Разрешает:** Исходящий трафик к `admin-back-end-api` + DNS (порт 53)

🧪 7. Тестирование
------------------

### Автоматическое тестирование

    test-bidirectional.bat

### Ручное тестирование

#### Тест 1: front-end → back-end-api (✅ должно работать)

    kubectl exec -n propdev-netpol front-end-app -- curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://back-end-api-app

**Ожидаемый результат:** 200

#### Тест 2: back-end-api → front-end (✅ должно работать)

    kubectl exec -n propdev-netpol back-end-api-app -- curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://front-end-app

**Ожидаемый результат:** 200

#### Тест 3: admin-front-end → admin-back-end-api (✅ должно работать)

    kubectl exec -n propdev-netpol admin-front-end-app -- curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://admin-back-end-api-app

**Ожидаемый результат:** 200

#### Тест 4: admin-back-end-api → admin-front-end (✅ должно работать)

    kubectl exec -n propdev-netpol admin-back-end-api-app -- curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://admin-front-end-app

**Ожидаемый результат:** 200

#### Тест 5: front-end → admin-back-end-api (❌ должно быть заблокировано)

    kubectl exec -n propdev-netpol front-end-app -- curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://admin-back-end-api-app

**Ожидаемый результат:** timeout

#### Тест 6: admin-front-end → back-end-api (❌ должно быть заблокировано)

    kubectl exec -n propdev-netpol admin-front-end-app -- curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://back-end-api-app

**Ожидаемый результат:** timeout

📊 8. ## 📊 Матрица сетевого трафика

| Источник              | Назначение                | Ожидаемый результат | Статус |
|-----------------------|---------------------------|---------------------|--------|
| front-end             | back-end-api              | ✅ Разрешено        | ✅     |
| back-end-api          | front-end                 | ✅ Разрешено        | ✅     |
| admin-front-end       | admin-back-end-api        | ✅ Разрешено        | ✅     |
| admin-back-end-api    | admin-front-end           | ✅ Разрешено        | ✅     |
| front-end             | admin-back-end-api        | ❌ Заблокировано    | ✅     |
| admin-front-end       | back-end-api              | ❌ Заблокировано    | ✅     |
| front-end             | admin-front-end           | ❌ Заблокировано    | ✅     |
| back-end-api          | admin-front-end           | ❌ Заблокировано    | ✅     |
| back-end-api          | admin-back-end-api        | ❌ Заблокировано    | ✅     |

---

**Легенда:**
- ✅ **Разрешено** — трафик проходит успешно (HTTP 200)
- ❌ **Заблокировано** — трафик отклоняется NetworkPolicy (timeout)


🔍 9. Отладка
-------------

### Проверка статуса подов

    kubectl get pods -n propdev-netpol --show-labels
    kubectl get pods -n kube-system -l k8s-app=calico-node

### Проверка сетевых политик

    kubectl get networkpolicies -n propdev-netpol
    kubectl describe networkpolicy allow-front-to-backend -n propdev-netpol

### Проверка DNS

    kubectl run test-dns --rm -i --image=busybox -n propdev-netpol -- nslookup back-end-api-app

### Проверка связи без политик

    kubectl delete networkpolicies --all -n propdev-netpol
    kubectl run test-connect --rm -i --image=busybox -n propdev-netpol -- nc -vz -w 3 back-end-api-app 80

### Просмотр логов Calico

    kubectl logs -n kube-system -l k8s-app=calico-node --tail=50

### Сброс и переустановка

    REM Полный сброс
    minikube delete
    minikube start --cni=calico --memory=4096 --cpus=2
    
    REM Подождать 2 минуты
    timeout /t 120
    
    REM Развернуть всё заново
    call create.bat

✅ 10. Результаты
----------------

### Что реализовано

*   ✅ Minikube с Calico CNI
*   ✅ 4 сервиса с метками (front-end, back-end-api, admin-front-end, admin-back-end-api)
*   ✅ 4 NetworkPolicy для двусторонней связи
*   ✅ Изоляция admin и non-admin трафика
*   ✅ Разрешён DNS для всех подов
*   ✅ Автоматические скрипты развёртывания и тестирования

### Файлы для сдачи

**Основной файл:** `non-admin-api-allow.yaml`

Этот файл содержит все сетевые политики и является основным артефактом выполнения задачи.

### Дополнительные материалы

*   `create.bat` — демонстрация полного цикла развёртывания
*   `test-bidirectional.bat` — демонстрация работоспособности политик
*   `deploy-services.bat` — развёртывание сервисов
*   `README.md` — документация
