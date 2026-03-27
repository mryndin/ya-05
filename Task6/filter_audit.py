import json
import os

def filter_audit():
    incidents = []
    if not os.path.exists('audit.log'):
        print("Error: audit.log not found!")
        return

    with open('audit.log', 'r', encoding='utf-8') as f:
        for line in f:
            try:
                event = json.loads(line)
                is_suspicious = False
                
                # Фильтр 1: Доступ к секретам
                if event.get('objectRef', {}).get('resource') == 'secrets':
                    is_suspicious = True
                
                # Фильтр 2: Привилегированные поды
                elif event.get('requestObject', {}).get('kind') == 'Pod':
                    containers = event['requestObject'].get('spec', {}).get('containers', [])
                    if any(c.get('securityContext', {}).get('privileged') for c in containers):
                        is_suspicious = True

                # Фильтр 3: Exec в поды
                elif event.get('objectRef', {}).get('subresource') == 'exec':
                    is_suspicious = True

                # Фильтр 4: Создание RoleBinding к админу
                elif event.get('objectRef', {}).get('resource') == 'rolebindings':
                    req = event.get('requestObject', {})
                    if req and req.get('roleRef', {}).get('name') == 'cluster-admin':
                        is_suspicious = True

                if is_suspicious:
                    incidents.append(event)
            except:
                continue

    with open('audit-extract.json', 'w', encoding='utf-8') as out:
        json.dump(incidents, out, indent=2, ensure_ascii=False)
    print(f"Extraction complete. Found {len(incidents)} suspicious events.")

if __name__ == "__main__":
    filter_audit()