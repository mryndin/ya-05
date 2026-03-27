# Task 4: Защита доступа к кластеру Kubernetes — PropDevelopment
**Статус:** ✅ Выполнено | **Дата:** 2026

## 📋 1. Таблица ролей и полномочий (RBAC)
| Роль | Права роли | Группы пользователей |
|------|-----------|---------------------|
| cluster-admin | * на все ресурсы во всех namespace | • Ведущие DevOps-инженеры • Специалист по ИБ (аудит) • Архитектор ПО |
| namespace-admin | * на ресурсы в своём namespace (кроме secrets, rbac) | • Team Lead Продажи • Team Lead ЖКУ • Team Lead Финансы |
| developer | get/list/watch/create/update/patch/delete на pods, deployments, services, configmaps | • Разработчики • Инженеры по эксплуатации |
| viewer | get/list/watch на pods, deployments, services, pods/log | • Бизнес-аналитики • Менеджеры • Аналитики BI |
| auditor | get/list/watch на secrets, audit logs, events (только чтение) | • Специалист по ИБ |

Принципы: Доступ по доменам (sales/utility/finance), минимальные привилегии, аудит без прав на изменение

## 📁 2. Структура файлов Task4
Task4/
├── README.md (этот файл)
├── create-users.bat (создание пользователей)
├── create-roles.bat (создание ролей)
├── create-bindings.bat (привязка ролей)
└── yaml/ (временные YAML-файлы)

## 🚀 3. Инструкция по запуску (Windows)
1. minikube start --memory=4096 --cpus=2
2. kubectl cluster-info
3. cd Task4
4. create-users.bat → create-roles.bat → create-bindings.bat
5. kubectl get sa --all-namespaces -l role
6. kubectl auth can-i list pods --as=system:serviceaccount:sales:dev-sales -n sales

## 🔐 4. Соответствие требованиям
| Требование | Реализация |
|------------|-----------|
| Ограничение доступа к кластеру | ClusterRole propdev-cluster-admin только для DevOps/ИБ |
| Привилегированные действия | ClusterRole propdev-auditor для чтения секретов |
| Группа на просмотр | ClusterRole propdev-viewer без прав на изменение |
| Группа для настройки | Role propdev-namespace-admin в своём namespace |
| Разграничение по структуре | Namespaces: sales, utility, finance + RoleBinding |
| Минимальные привилегии | Разработчики без доступа к secrets, аналитики read-only |

## 🧪 5. Тестирование доступа
| Пользователь | Действие | Ресурс | Ожидаемо |
|--------------|----------|--------|----------|
| dev-sales | list pods | sales | ✅ yes |
| dev-sales | get secrets | sales | ❌ no |
| analyst-bi | list pods | все namespace | ✅ yes |
| analyst-bi | delete pods | любой | ❌ no |
| security-auditor | get secrets | все | ✅ yes |
| security-auditor | delete secrets | любой | ❌ no |

## ⚠️ 6. Примечания
- Кодировка: chcp 65001 для UTF-8
- YAML в папке yaml/ не удалять до завершения
- Запуск строго по порядку: users → roles → bindings
- Очистка: kubectl delete -f yaml/ && rmdir /s /q yaml
- Продакшен: использовать LDAP/AD через OIDC вместо сервис-аккаунтов

## 📊 7. Сводка по ролям
| Роль | Тип | Namespace | Критичность |
|------|-----|-----------|-------------|
| propdev-cluster-admin | ClusterRole | Все | 🔴 Критическая |
| propdev-auditor | ClusterRole | Все | 🟠 Высокая |
| propdev-viewer | ClusterRole | Все | 🟡 Средняя |
| propdev-namespace-admin | Role | sales/utility/finance | 🟠 Высокая |
| propdev-developer | Role | sales/utility/finance/data-platform | 🟡 Средняя |

## 🔗 8. Связь с задачами
Task 1 (Аудит) → Выявлены проблемы доступа → решается RBAC
Task 2 (Чек-лист) → Раздел I (IAM) → реализовано в Kubernetes
Task 3 (Умный дом) → Сервисы в namespace smart-home с аналогичной моделью
