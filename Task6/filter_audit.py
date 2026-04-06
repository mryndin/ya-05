import json

audit_log_path = "audit.log"
output_json_path = "audit-extract.json"

suspicious_events = []

try:
    with open(audit_log_path, "r") as file:
        for line in file:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            user_info = event.get("user", {})
            username = user_info.get("username", "")
            object_ref = event.get("objectRef", {}) or {}
            namespace = object_ref.get("namespace", "")
            resource = object_ref.get("resource", "")
            verb = event.get("verb", "")

            is_suspicious = False

            # 1. Запросы от имени сервисного аккаунта monitoring или активность в secure-ops
            if "monitoring" in username or namespace == "secure-ops":
                is_suspicious = True

            # 2. Попытки выполнения команд (exec) в системных подах
            if object_ref.get("subresource") == "exec":
                is_suspicious = True

            # 3. Попытки чтения секретов в kube-system
            if resource == "secrets" and namespace == "kube-system":
                is_suspicious = True

            # 4. Попытки создания привилегированных контейнеров
            req_object = event.get("requestObject", {}) or {}
            if req_object and "spec" in req_object:
                containers = req_object["spec"].get("containers", [])
                for container in containers:
                    if (
                        container.get("securityContext", {}).get("privileged")
                        is True
                    ):
                        is_suspicious = True
                        break

            # 5. Назначение роли cluster-admin
            if resource in ["rolebindings", "clusterrolebindings"]:
                is_suspicious = True

            if is_suspicious:
                suspicious_events.append(event)

    # Сохранение выжимки в файл
    with open(output_json_path, "w", encoding="utf-8") as out_file:
        json.dump(suspicious_events, out_file, indent=2, ensure_ascii=False)

    print(
        f"Анализ завершен. Найдено {len(suspicious_events)} подозрительных событий. Выгружено в {output_json_path}"
    )

except FileNotFoundError:
    print(
        f"Файл {audit_log_path} не найден. Убедитесь, что вы скопировали лог в текущую папку под этим именем."
    )