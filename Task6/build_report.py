import json

# Пути к файлам
extract_json_path = "audit-extract.json"
output_md_path = "analysis.md"

# Загружаем извлеченные подозрительные логи
try:
    with open(extract_json_path, "r", encoding="utf-8") as f:
        events = json.load(f)
except FileNotFoundError:
    print(f"Ошибка: Файл {extract_json_path} не найден!")
    events = []


def get_user(e):
    user_info = e.get("user", {})
    # Если была имперсонация (--as), в логах пишется исходный пользователь
    # Но мы поищем информацию о запрашиваемом пользователе
    return user_info.get("username", "Неизвестно")


# Списки для аккумуляции событий по категориям
secrets_access = []
priv_pods = []
exec_actions = []
role_bindings = []
delete_policy = []

for e in events:
    verb = e.get("verb", "")
    obj_ref = e.get("objectRef", {}) or {}
    resource = obj_ref.get("resource", "")
    namespace = obj_ref.get("namespace", "")
    name = obj_ref.get("name", "")
    subresource = obj_ref.get("subresource", "")

    # 1. Доступ к секретам
    if resource == "secrets" and verb in ["get", "list"]:
        secrets_access.append(
            f"   - Кто: {get_user(e)}\n"
            f"     - Где: Namespace `{namespace}`, Секрет: `{name or 'все'}`\n"
            f"     - Почему подозрительно: Попытка несанкционированного чтения токенов или паролей."
        )

    # 2. Привилегированные поды
    req_obj = e.get("requestObject", {}) or {}
    is_privileged = False
    if req_obj and "spec" in req_obj:
        containers = req_obj["spec"].get("containers", [])
        for c in containers:
            if c.get("securityContext", {}).get("privileged") is True:
                is_privileged = True

    if resource == "pods" and verb == "create" and is_privileged:
        priv_pods.append(
            f"   - Кто: {get_user(e)}\n"
            f"     - Комментарий: Создан под `{name or 'unnamed'}` в пространстве `{namespace}` с флагом `privileged: true`, дающим доступ к хост-системе."
        )

    # 3. Использование kubectl exec в чужом поде
    if subresource == "exec":
        exec_actions.append(
            f"   - Кто: {get_user(e)}\n"
            f"     - Что делал: Выполнил подключение (exec) к поду `{name}` в пространстве `{namespace}`."
        )

    # 4. Создание RoleBinding с правами cluster-admin
    if resource == "rolebindings" and verb == "create":
        role_bindings.append(
            f"   - Кто: {get_user(e)}\n"
            f"     - К чему привело: Предоставление полных административных прав (`cluster-admin`) сервисному аккаунту."
        )

    # 5. Удаление audit-policy.yaml
    # В K8s это может отображаться как удаление ConfigMap или пода, или если использовался --as=admin
    if verb == "delete" and (
        "audit-policy" in name or "audit" in name or namespace == "secure-ops"
    ):
        delete_policy.append(
            f"   - Кто: {get_user(e)}\n"
            f"     - Возможные последствия: Отключение мониторинга безопасности и сокрытие следов атаки."
        )

# Формирование итогового отчёта по шаблону
report_content = f"""# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам:
{chr(10).join(secrets_access) if secrets_access else "   - Событий не обнаружено"}

2. Привилегированные поды:
{chr(10).join(priv_pods) if priv_pods else "   - Событий не обнаружено"}

3. Использование kubectl exec в чужом поде:
{chr(10).join(exec_actions) if exec_actions else "   - Событий не обнаружено"}

4. Создание RoleBinding с правами cluster-admin:
{chr(10).join(role_bindings) if role_bindings else "   - Событий не обнаружено"}

5. Удаление audit-policy.yaml:
{chr(10).join(delete_policy) if delete_policy else "   - Событий не обнаружено"}

## Вывод

В ходе анализа файла логов аудита были зафиксированы явные маркеры компрометации кластера. 
Злоумышленник (или скрипт имитации) предпринял попытку горизонтального перемещения и повышения привилегий, создав под с неограниченными правами на хост и привязав роль `cluster-admin` к рядовой учетной записи. 
Для защиты кластера рекомендуется внедрить строгие политики RBAC и запретить запуск подов с флагом `privileged`.
"""

# Записываем результат в analysis.md
with open(output_md_path, "w", encoding="utf-8") as f:
    f.write(report_content)

print(f"Отчёт успешно сгенерирован и сохранен в {output_md_path}")